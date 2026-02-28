import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/forget_pass_view_model.dart';
import 'otp_screen.dart';

class ForgetPassScreen extends StatelessWidget {
  const ForgetPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Decision: Use ChangeNotifierProvider here. 
    // Sub-screens will use ChangeNotifierProvider.value when pushed.
    return ChangeNotifierProvider(
      create: (_) => ForgetPassViewModel(),
      child: const _ForgetPassContent(),
    );
  }
}

class _ForgetPassContent extends StatelessWidget {
  const _ForgetPassContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ForgetPassViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: viewModel.emailFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Forgot Password',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email to receive a reset code',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Text('Email Address', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: viewModel.emailController,
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                
                if (viewModel.errorMessage != null) ...[
                 const SizedBox(height: 16),
                 Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Send OTP',
                  isLoading: viewModel.isLoading,
                  onPressed: () async {
                    await viewModel.sendOtp(context);
                    if (viewModel.currentStep == ForgotPasswordStep.otpInput && context.mounted) {
                       // Navigate to OTP Screen, passing the ViewModel via provider value
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (_) => ChangeNotifierProvider.value(
                             value: viewModel,
                             child: const OtpScreen(),
                           ),
                         ),
                       );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
