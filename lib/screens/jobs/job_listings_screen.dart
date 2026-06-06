import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/routes.dart';
import '../../view_model/jobs_view_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../widgets/job_card.dart';
import '../../widgets/report_bottom_sheet.dart';

class CareerOpportunitiesScreen extends StatefulWidget {
  const CareerOpportunitiesScreen({super.key});

  @override
  State<CareerOpportunitiesScreen> createState() => _CareerOpportunitiesScreenState();
}

class _CareerOpportunitiesScreenState extends State<CareerOpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSavedOnly = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<JobsViewModel>().fetchJobs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Career Opportunities', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: PopupMenuButton<bool>(
                  icon: const Icon(Icons.tune, color: AppColors.textSecondary),
                  onSelected: (bool showSaved) {
                    setState(() {
                      _showSavedOnly = showSaved;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<bool>>[
                    PopupMenuItem<bool>(
                      value: false,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: !_showSavedOnly ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Newest Jobs',
                            style: TextStyle(
                              color: !_showSavedOnly ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: !_showSavedOnly ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<bool>(
                      value: true,
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark,
                            color: _showSavedOnly ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saved Jobs',
                            style: TextStyle(
                              color: _showSavedOnly ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: _showSavedOnly ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                context.read<JobsViewModel>().filterJobs(query: value);
              },
            ),
          ),
          Expanded(
            child: _buildJobsList(),
          ),
        ],
      ),
      floatingActionButton: _buildPostJobFAB(context),
    );
  }

  Widget? _buildPostJobFAB(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final role = authVm.currentUser?.role?.toLowerCase() ?? '';
    
    if (role == 'senior' || role == 'alumni') {
      return FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.postJob),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return null;
  }

  Widget _buildJobsList() {
    return Consumer<JobsViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        
        final filteredJobs = vm.filteredJobs;
        final jobsToShow = _showSavedOnly ? vm.savedJobs : filteredJobs;
        
        if (jobsToShow.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_outline, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('No career opportunities yet.', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobsToShow.length,
          itemBuilder: (context, index) {
            final job = jobsToShow[index];
            return JobCard(
              job: job,
              onApply: () {
                if (job.jobUrl.isNotEmpty) {
                  _launchUrl(job.jobUrl);
                }
              },
              onSave: () {
                context.read<JobsViewModel>().toggleSaveJob(job);
              },
              onReport: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ReportBottomSheet(
                    targetUserId: job.creatorId,
                    targetContentId: job.id,
                    contentType: 'job',
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
