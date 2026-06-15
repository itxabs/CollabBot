import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../core/constants/routes.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('Profile', style: AppTextStyles.h2),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildProfileInfoTab(context, viewModel, authViewModel),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Skills',
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillsListScreen()));
                      if (context.mounted) {
                        await viewModel.refresh();
                      }
                    },
                    child: _buildSkillsList(viewModel.skills),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Experience',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExperienceListScreen())),
                    child: _buildExperienceList(viewModel.experiences),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Social Links',
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialMediaScreen()));
                      if (context.mounted) {
                        await viewModel.refresh();
                      }
                    },
                    child: _buildSocialLinksList(viewModel.socialLinks),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileListTile(
                    title: 'Resume Analyzer',
                    icon: Icons.description_outlined,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResumeAnalyzerScreen())),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 16),
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
        GestureDetector(
          onTap: viewModel.isUploading ? null : viewModel.pickAndUploadImage,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 45, color: AppColors.primary)
                      : null,
                ),
              ),
              if (viewModel.isUploading)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!viewModel.isUploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(user.fullName, style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(user.role, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required VoidCallback onTap, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: title, onTap: onTap),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSkillsList(List<UserSkill> skills) {
    if (skills.isEmpty) return const Text('No skills added yet', style: TextStyle(color: AppColors.textSecondary));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        final bool isVerified = skill.isVerified;
        return Chip(
          avatar: Icon(
            isVerified ? Icons.check_circle_outline : Icons.access_time,
            size: 16,
            color: isVerified ? AppColors.tealDark : AppColors.textSecondary,
          ),
          label: Text(
            skill.skillName,
            style: TextStyle(
              color: isVerified ? AppColors.tealDark : AppColors.textSecondary,
              fontWeight: isVerified ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isVerified ? AppColors.tealLight : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isVerified ? AppColors.tealLight : AppColors.border),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceList(List<Experience> experiences) {
    if (experiences.isEmpty) return const Text('No experience added yet', style: TextStyle(color: AppColors.textSecondary));
    return Column(
      children: experiences.map((exp) {
        final String startDate = DateFormat('MMM yyyy').format(exp.startDate);
        final String endDate = exp.endDate != null ? DateFormat('MMM yyyy').format(exp.endDate!) : 'Present';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exp.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(exp.organization, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text('$startDate - $endDate', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialLinksList(List<UserSocialLink> links) {
    if (links.isEmpty) return const Text('No social links added yet', style: TextStyle(color: AppColors.textSecondary));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: links.map((link) => InkWell(
        onTap: () async {
          final uri = Uri.parse(link.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _getPlatformIcon(link.platform, size: 24),
        ),
      )).toList(),
    );
  }

  Widget _getPlatformIcon(String platform, {double size = 24, Color color = AppColors.primary}) {
    switch (platform.toLowerCase()) {
      case 'linkedin': return FaIcon(FontAwesomeIcons.linkedin, size: size, color: color);
      case 'github': return FaIcon(FontAwesomeIcons.github, size: size, color: color);
      case 'facebook': return FaIcon(FontAwesomeIcons.facebook, size: size, color: color);
      case 'twitter': return FaIcon(FontAwesomeIcons.xTwitter, size: size, color: color);
      case 'instagram': return FaIcon(FontAwesomeIcons.instagram, size: size, color: color);
      case 'website': return Icon(Icons.language, size: size, color: color);
      default: return Icon(Icons.link, size: size, color: color);
    }
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
