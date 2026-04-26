import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/forget_pass_view_model.dart';

class PasswordUpdateScreen extends StatelessWidget {
  const PasswordUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ForgetPassViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't allow backing out easily
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: viewModel.passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set New Password',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Text('New Password', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: viewModel.newPasswordController,
                  hintText: 'Enter new password',
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                   validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text('Confirm Password', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: viewModel.confirmPasswordController,
                  hintText: 'Confirm new password',
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                   validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm password';
                    return null;
                  },
                ),

                if (viewModel.errorMessage != null) ...[
                 const SizedBox(height: 16),
                 Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Save Changes',
                  isLoading: viewModel.isLoading,
                  onPressed: () => viewModel.updatePassword(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
