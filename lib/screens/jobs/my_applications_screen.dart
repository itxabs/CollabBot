import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../view_model/jobs_view_model.dart';
import 'package:intl/intl.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<JobsViewModel>(
        builder: (context, vm, child) {
          if (vm.myApplications.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.myApplications.length,
            itemBuilder: (context, index) {
              final job = vm.myApplications[index];
              return _buildApplicationCard(job);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(dynamic job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(job.company.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(job.company, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Applied on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          _buildStatusBadge(job.applicationStatus ?? 'Pending'),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'viewed':
        color = AppColors.primary;
        bgColor = AppColors.primaryLight;
        break;
      case 'shortlisted':
        color = AppColors.tealAccent;
        bgColor = AppColors.tealLight;
        break;
      case 'rejected':
        color = AppColors.error;
        bgColor = AppColors.error.withOpacity(0.1);
        break;
      case 'pending':
      default:
        color = Colors.amber[800]!;
        bgColor = Colors.amber[50]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No applications yet', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
