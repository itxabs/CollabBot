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

    if (viewModel.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: () => viewModel.logout(context, authViewModel),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Ensure scrollable even if content is short
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Section
                _buildHeader(viewModel),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // 2. Skills Section
                      _buildSectionHeader(
                        title: 'Skills',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SkillsListScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSkillsList(viewModel.skills),

                      const SizedBox(height: 32),

                      // 3. Experience Section
                      _buildSectionHeader(
                        title: 'Experience',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExperienceListScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildExperienceList(viewModel.experiences),

                      const SizedBox(height: 32),

                      // 4. Social Media Section
                      _buildSectionHeader(
                        title: 'Social Media',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider(
                                create: (_) => SocialMediaViewModel(),
                                child: const SocialMediaScreen(),
                              ),
                            ),
                          ).then((_) => viewModel.refresh());
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSocialMediaList(viewModel.socialLinks),

                      const SizedBox(height: 32),

                      // 5. Additional Sections (Resume & Leaderboard)
                      _buildProfileListTile(
                        title: 'Resume Analyzer',
                        icon: Icons.description_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResumeAnalyzerScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildProfileListTile(
                        title: 'Leaderboard',
                        icon: Icons.leaderboard_outlined,
                        onTap: () {
                          // TODO: Implement Leaderboard navigation
                        },
                      ),

                      const SizedBox(height: 32),

                      // 5. Footer (Date Joined)
                      if (viewModel.user != null)
                        Center(
                          child: Text(
                            viewModel.joinedDateString,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Logout
                      TextButton(
                        onPressed: () =>
                            viewModel.logout(context, authViewModel),
                        child: Text(
                          'Log Out',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ProfileViewModel viewModel) {
    if (viewModel.user == null) return const SizedBox.shrink();
    final user = viewModel.user!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
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
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(user.fullName, style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            user.role,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsList(List<UserSkill> skills) {
    if (skills.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No skills added yet',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        final bool isVerified = skill.isVerified;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isVerified
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Text(
            skill.skillName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isVerified ? AppColors.success : AppColors.textPrimary,
              fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceList(List<Experience> experiences) {
    if (experiences.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No experience added yet',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: experiences.map((exp) {
        final String startDate = DateFormat('MMM yyyy').format(exp.startDate);
        final String endDate = exp.endDate != null
            ? DateFormat('MMM yyyy').format(exp.endDate!)
            : 'Present';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.work_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(exp.organization, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '$startDate - $endDate',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileListTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSocialMediaList(List<UserSocialLink> socialLinks) {
    if (socialLinks.isEmpty) {
      return const Text(
        'No social profiles added',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: socialLinks.map((link) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () async {
              final Uri url = Uri.parse(link.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getPlatformIcon(link.platform, size: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    link.url,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
}
