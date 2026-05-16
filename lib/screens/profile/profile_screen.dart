import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/profile_view_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../data/models/profile_models.dart';
import '../skills/skills_list_screen.dart';
import '../experience/experience_list_screen.dart';
import '../resume/resume_analyzer_screen.dart';
import 'social_media_screen.dart';
import '../../view_model/social_media_view_model.dart';
import '../../view_model/jobs_view_model.dart';
import '../../widgets/job_card.dart';
import '../../core/constants/routes.dart';
import '../jobs/job_listings_screen.dart'; // This is now CareerOpportunitiesScreen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const _ProfileContent(),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (viewModel.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0, // Hide main toolbar
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Profile Info'),
              Tab(text: 'Career Opportunities'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileInfoTab(context, viewModel, authViewModel),
            CareerOpportunitiesScreen(), // Re-using simplified listings screen here
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTab(BuildContext context, ProfileViewModel viewModel, AuthViewModel authViewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            _buildHeader(viewModel),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildSectionHeader(
                    title: 'Skills',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillsListScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildSkillsList(viewModel.skills),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    title: 'Experience',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExperienceListScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildExperienceList(viewModel.experiences),
                  const SizedBox(height: 32),
                  _buildProfileListTile(
                    title: 'Resume Analyzer',
                    icon: Icons.description_outlined,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResumeAnalyzerScreen())),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => viewModel.logout(context, authViewModel),
                    child: Text('Log Out', style: AppTextStyles.button.copyWith(color: AppColors.error)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProfileViewModel viewModel) {
    if (viewModel.user == null) return const SizedBox.shrink();
    final user = viewModel.user!;

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: viewModel.isUploading ? null : viewModel.pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.primary.withOpacity(0.05),
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 45, color: AppColors.primary)
                      : null,
                ),
              ),
            ),
            if (viewModel.isUploading)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.fullName, style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(user.role, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          onPressed: onTap,
        ),
      ],
    );
  }

  Widget _buildSkillsList(List<UserSkill> skills) {
    if (skills.isEmpty) return const Text('No skills added yet', style: TextStyle(color: AppColors.textSecondary));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => Chip(
        label: Text(skill.skillName),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
      )).toList(),
    );
  }

  Widget _buildExperienceList(List<Experience> experiences) {
    if (experiences.isEmpty) return const Text('No experience added yet', style: TextStyle(color: AppColors.textSecondary));
    return Column(
      children: experiences.map((exp) => ListTile(
        leading: const Icon(Icons.work_outline, color: AppColors.primary),
        title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(exp.organization),
      )).toList(),
    );
  }

  Widget _buildProfileListTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
    );
  }
}
