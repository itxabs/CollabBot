import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/forget_pass_view_model.dart';
import 'password_update_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ViewModel is provided by value from previous screen
    final viewModel = Provider.of<ForgetPassViewModel>(context);

    // Helper to build a digit field
    Widget buildDigitField(int index) {
      return SizedBox(
        width: 40, // Reduced width to fit 8 digits or 4x2
        height: 50,
        child: TextField(
          controller: viewModel.otpControllers[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: AppTextStyles.h2.copyWith(fontSize: 20), // Slightly smaller font
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (value) => viewModel.onOtpDigitEntered(index, value, context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Verification', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Enter the 8-digit code sent to ${viewModel.emailController.text}', 
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 48),

              // Layout for 8 digits: Split into 2 rows of 4 for better spacing
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => buildDigitField(index)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => buildDigitField(index + 4)),
                  ),
                ],
              ),

              if (viewModel.errorMessage != null) ...[
                 const SizedBox(height: 16),
                 Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],

              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Verify OTP',
                isLoading: viewModel.isLoading,
                onPressed: () async {
                  await viewModel.verifyOtp(context);
                  if (viewModel.currentStep == ForgotPasswordStep.passwordUpdate && context.mounted) {
                     Navigator.pushReplacement(
                       context,
                       MaterialPageRoute(
                         builder: (_) => ChangeNotifierProvider.value(
                           value: viewModel,
                           child: const PasswordUpdateScreen(),
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
    );
  }
}
