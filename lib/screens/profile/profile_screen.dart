import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/profile_view_model.dart';
import '../../core/widgets/primary_button.dart';

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

    if (viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(viewModel.user?.name ?? 'User', style: AppTextStyles.h2),
                    Text(viewModel.user?.role ?? 'Role', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Settings Sections
              _buildSectionTitle('Account'),
              _buildSettingsItem(Icons.person_outline, 'Personal Information', onTap: () {}),
              _buildSettingsItem(Icons.notifications_outlined, 'Notifications', onTap: () {}),
              _buildSettingsItem(Icons.lock_outline, 'Security', onTap: () {}),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Support'),
              _buildSettingsItem(Icons.help_outline, 'Help Center', onTap: () {}),
              _buildSettingsItem(Icons.info_outline, 'About Us', onTap: () {}),

              const SizedBox(height: 48),
              
              PrimaryButton(
                text: 'Log Out',
                onPressed: () => viewModel.logout(context),
                backgroundColor: Colors.white,
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
