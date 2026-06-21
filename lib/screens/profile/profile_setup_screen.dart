import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/profile_setup_view_model.dart';
import '../../view_model/education_view_model.dart';
import '../../view_model/experience_view_model.dart';
import '../../view_model/skills_view_model.dart';
import '../education/add_education_screen.dart';
import '../experience/add_experience_screen.dart';
import '../skills/add_skill_screen.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../view_model/social_media_view_model.dart';
import 'social_media_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EducationViewModel>(context, listen: false).loadEducation();
      Provider.of<ExperienceViewModel>(context, listen: false).loadExperiences();
      Provider.of<SkillsViewModel>(context, listen: false).loadData();
      Provider.of<ProfileSetupViewModel>(context, listen: false).loadSocialLinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileSetupViewModel>(context);
    final eduViewModel = Provider.of<EducationViewModel>(context);
    final expViewModel = Provider.of<ExperienceViewModel>(context);
    final skillsViewModel = Provider.of<SkillsViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile Setup', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Avatar with Initials
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: viewModel.isUploading ? null : viewModel.pickAndUploadImage,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: AppColors.primary.withOpacity(0.05),
                              backgroundImage: viewModel.avatarUrl != null && viewModel.avatarUrl!.isNotEmpty
                                  ? NetworkImage(viewModel.avatarUrl!)
                                  : null,
                              child: viewModel.avatarUrl == null || viewModel.avatarUrl!.isEmpty
                                  ? Text(
                                      viewModel.initials,
                                      style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 28),
                                    )
                                  : null,
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
                            bottom: 4,
                            right: 4,
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 2. Skills Section (Matching Experience style)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Skills'),
                  IconButton(
                    icon: _buildAddIcon(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddSkillScreen(),
                        ),
                      ).then((_) => skillsViewModel.loadData());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSkillsList(skillsViewModel),

              const SizedBox(height: 32),

              // 3. Education Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Education'),
                  IconButton(
                    icon: _buildAddIcon(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: eduViewModel,
                            child: const AddEducationScreen(),
                          ),
                        ),
                      ).then((_) => eduViewModel.loadEducation());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildEducationList(eduViewModel),

              const SizedBox(height: 32),

              // 4. Experience Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Experience'),
                  IconButton(
                    icon: _buildAddIcon(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: expViewModel,
                            child: const AddExperienceScreen(),
                          ),
                        ),
                      ).then((_) => expViewModel.loadExperiences());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildExperienceList(expViewModel),

              const SizedBox(height: 32),

              // 4. Social Media Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Social Media'),
                  IconButton(
                    icon: _buildAddIcon(),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => SocialMediaViewModel(),
                            child: const SocialMediaScreen(),
                          ),
                        ),
                      ).then((_) => viewModel.loadSocialLinks());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSocialMediaSection(viewModel),

              const SizedBox(height: 48),

              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              ElevatedButton(
                onPressed: viewModel.isLoading ? null : () => viewModel.completeProfile(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Complete Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 20),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSkillsList(SkillsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (viewModel.skills.isEmpty) {
      return _buildEmptyState('No skills added yet');
    }

    return Column(
      children: viewModel.skills.map((skill) {
        final levelName = viewModel.getLevelName(skill.skillLevelId);
        return _buildListItem(
          title: skill.skillName,
          subtitle: levelName,
          icon: Icons.psychology_outlined,
        );
      }).toList(),
    );
  }

  Widget _buildEducationList(EducationViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (viewModel.education.isEmpty) {
      return _buildEmptyState('No education added yet');
    }

    return Column(
      children: viewModel.education.map((edu) {
        final parts = [
          if (edu.degree != null && edu.degree!.isNotEmpty) edu.degree!,
          if (edu.fieldOfStudy != null && edu.fieldOfStudy!.isNotEmpty) edu.fieldOfStudy!,
        ];
        final subtitle = parts.isNotEmpty ? parts.join(' • ') : edu.institution;
        return _buildListItem(
          title: edu.institution,
          subtitle: subtitle,
          icon: Icons.school_outlined,
        );
      }).toList(),
    );
  }

  Widget _buildExperienceList(ExperienceViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (viewModel.experiences.isEmpty) {
      return _buildEmptyState('No experience added yet');
    }

    return Column(
      children: viewModel.experiences.map((exp) {
        final String startDate = DateFormat('MMM yyyy').format(exp.startDate);
        final String endDate = exp.endDate != null 
            ? DateFormat('MMM yyyy').format(exp.endDate!) 
            : 'Present';

        return _buildListItem(
          title: exp.title,
          subtitle: '${exp.organization} • $startDate - $endDate',
          icon: Icons.work_outline,
        );
      }).toList(),
    );
  }

  Widget _buildSocialMediaSection(ProfileSetupViewModel viewModel) {
    if (viewModel.isLoading && viewModel.socialLinks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.socialLinks.isEmpty) {
      return _buildEmptyState('No social links added yet');
    }

    return Column(
      children: viewModel.socialLinks.map((link) {
        return _buildListItem(
          title: link.platform.toUpperCase(),
          subtitle: link.url,
          iconWidget: _getPlatformIcon(link.platform),
        );
      }).toList(),
    );
  }

  Widget _getPlatformIcon(String platform, {double size = 20, Color color = AppColors.primary}) {
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

  Widget _buildListItem({required String title, required String subtitle, IconData? icon, Widget? iconWidget}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: iconWidget ?? Icon(icon!, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
