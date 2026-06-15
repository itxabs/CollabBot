import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _filter = 'All'; // 'All', 'Active', 'Expired'

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<JobsViewModel>().fetchJobs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Career Opportunities', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('Show All')),
              const PopupMenuItem(value: 'Active', child: Text('Active Only')),
              const PopupMenuItem(value: 'Expired', child: Text('Expired Only')),
            ],
          ),
        ],
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
        
        if (_filter == 'Active') {
          filteredJobs = filteredJobs.where((j) => j.deadline == null || j.deadline!.isAfter(DateTime.now())).toList();
        } else if (_filter == 'Expired') {
          filteredJobs = filteredJobs.where((j) => j.deadline != null && j.deadline!.isBefore(DateTime.now())).toList();
        }
        
        if (filteredJobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_outline, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(_filter == 'All' ? 'No career opportunities yet.' : 'No $_filter jobs found.', style: const TextStyle(color: AppColors.textSecondary)),
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
              onTap: () => Navigator.pushNamed(
                context, 
                AppRoutes.jobDetail, 
                arguments: job
              ),
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
