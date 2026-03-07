import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/signup_view_model.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupViewModel(),
      child: const _SignupContent(),
    );
  }
}

class _SignupContent extends StatelessWidget {
  const _SignupContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SignupViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (viewModel.currentStep == 2) {
              viewModel.previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${viewModel.currentStep} of 2',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    viewModel.errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: viewModel.currentStep == 1
                    ? const _StepOneInputs()
                    : const _StepTwoRoles(),
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                text: viewModel.currentStep == 1 ? 'Continue' : 'Create Account',
                isLoading: viewModel.isLoading,
                onPressed: () {
                  if (viewModel.currentStep == 1) {
                    viewModel.nextStep();
                  } else {
                    viewModel.signUp(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepOneInputs extends StatelessWidget {
  const _StepOneInputs();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SignupViewModel>(context, listen: false);
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Full Name', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: viewModel.nameController,
          hintText: 'Enter your full name',
          prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Text('Email Address', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: viewModel.emailController,
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Text('Password', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: viewModel.passwordController,
          hintText: 'Create a password',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StepTwoRoles extends StatelessWidget {
  const _StepTwoRoles();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SignupViewModel>(context);
    
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your role',
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _RoleCard(
          title: 'Junior',
          description: 'Learning the ropes',
          isSelected: viewModel.selectedRole == 'junior',
          onTap: () => viewModel.selectRole('junior'),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          title: 'Senior',
          description: 'Experienced student',
          isSelected: viewModel.selectedRole == 'senior',
          onTap: () => viewModel.selectRole('senior'),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          title: 'Alumni',
          description: 'Graduated professional',
          isSelected: viewModel.selectedRole == 'alumni',
          onTap: () => viewModel.selectRole('alumni'),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
