import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/routes.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/jobs_view_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../widgets/job_card.dart';
import '../../widgets/report_bottom_sheet.dart';
import '../../widgets/custom_search_bar.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Bar
            Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Career Opportunities', style: AppTextStyles.h2),
                      Text(
                        'Discover and apply to new roles!',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(
                      hintText: 'Search jobs by title...',
                      controller: _searchController,
                      onChanged: (value) {
                        context.read<JobsViewModel>().filterJobs(query: value);
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showSavedOnly ? Icons.bookmark_rounded : Icons.tune_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _showFilterSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildJobsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildPostJobFAB(context),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Filter Jobs', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              _FilterOption(
                icon: Icons.access_time_rounded,
                title: 'Newest Jobs',
                isSelected: !_showSavedOnly,
                onTap: () {
                  setState(() {
                    _showSavedOnly = false;
                  });
                  setBottomSheetState(() {});
                  Navigator.pop(context);
                },
              ),
              _FilterOption(
                icon: Icons.bookmark_rounded,
                title: 'Saved Jobs',
                isSelected: _showSavedOnly,
                onTap: () {
                  setState(() {
                    _showSavedOnly = true;
                  });
                  setBottomSheetState(() {});
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
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

class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
    );
  }
}
