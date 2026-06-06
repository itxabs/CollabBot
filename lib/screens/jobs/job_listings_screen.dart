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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<JobsViewModel>().fetchJobs());
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
      body: _buildJobsList(),
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
        
        var filteredJobs = vm.allJobs.where((j) => j.status == 'Approved').toList();
        
        if (filteredJobs.isEmpty) {
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
          itemCount: filteredJobs.length,
          itemBuilder: (context, index) {
            final job = filteredJobs[index];
            return JobCard(
              job: job,
              onTap: () {
                if (job.jobUrl.isNotEmpty) {
                  _launchUrl(job.jobUrl);
                }
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
