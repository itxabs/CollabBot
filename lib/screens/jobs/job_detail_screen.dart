import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/routes.dart';
import '../../data/models/job_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/jobs_view_model.dart';
import '../../view_model/skills_view_model.dart';
import '../../widgets/report_bottom_sheet.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isApplied = false;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final userId = context.read<AuthViewModel>().currentUser?.userId;
    if (userId != null) {
      final applied = await context.read<JobsViewModel>().checkIfApplied(userId, widget.job.id);
      if (mounted) {
        setState(() {
          _isApplied = applied;
          _checkingStatus = false;
        });
      }
    } else {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 24),
                  _buildTabContent(),
                ],
              ),
            ),
          ),
          _buildStickyBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Hero(
          tag: 'avatar_${widget.job.id}',
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.job.company.isNotEmpty ? widget.job.company.substring(0, 1).toUpperCase() : 'J',
                style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.job.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.job.company} • ${widget.job.location}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Text(
          widget.job.salaryRange,
          style: const TextStyle(color: AppColors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Requirements'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 400, // Fixed height for tab content or use Expanded carefully
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRequirementsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(widget.job.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          const Text('Employment Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(widget.job.employmentType, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 24),
          if (widget.job.deadline != null) ...[
            const SizedBox(height: 24),
            const Text('Application Deadline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy').format(widget.job.deadline!),
              style: TextStyle(
                color: widget.job.deadline!.isBefore(DateTime.now()) ? Colors.red : AppColors.textSecondary,
                fontWeight: widget.job.deadline!.isBefore(DateTime.now()) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementsTab() {
    final userSkills = context.read<SkillsViewModel>().skills.map((s) => s.skillName.toLowerCase()).toList();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.job.skills.isNotEmpty) ...[
            const Text('Skills & Expertise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...widget.job.skills.map((skill) {
              final matches = userSkills.contains(skill.toLowerCase());
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      matches ? Icons.check_circle : Icons.circle_outlined, 
                      color: matches ? AppColors.tealAccent : Colors.grey[300],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      skill, 
                      style: TextStyle(
                        color: matches ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: matches ? FontWeight.w600 : FontWeight.normal,
                      )
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          if (widget.job.requirements.isNotEmpty) ...[
            const Text('Job Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...widget.job.requirements.map((req) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $req', style: const TextStyle(color: AppColors.textSecondary)),
              )
            ),
          ],
          if (widget.job.skills.isEmpty && widget.job.requirements.isEmpty)
            const Center(child: Text('No specific requirements listed.', style: TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    final isPastDeadline = widget.job.deadline != null && widget.job.deadline!.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: (_isApplied || _checkingStatus || isPastDeadline) 
                    ? null 
                    : () => Navigator.pushNamed(context, AppRoutes.jobApplication, arguments: widget.job).then((_) => _checkApplicationStatus()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPastDeadline ? Colors.grey : (_isApplied ? Colors.grey : AppColors.primary),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _checkingStatus 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isPastDeadline ? 'Deadline Passed' : (_isApplied ? 'Applied' : 'Apply Now'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
