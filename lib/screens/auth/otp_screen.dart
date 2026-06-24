import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../view_model/forget_pass_view_model.dart';
import 'password_update_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late List<FocusNode> _focusNodes;
  int _cooldownSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(8, (index) => FocusNode());
    for (var node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _startCooldown();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ForgetPassViewModel>(context);

    // Helper to build an individual digit field
    Widget buildDigitField(int index) {
      final isFocused = _focusNodes[index].hasFocus;
      final hasValue = viewModel.otpControllers[index].text.isNotEmpty;

      return AspectRatio(
        aspectRatio: 0.73,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 38, maxHeight: 52),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused
                  ? AppColors.primary
                  : (hasValue ? AppColors.secondary : AppColors.border),
              width: isFocused ? 2 : 1.5,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: TextField(
              controller: viewModel.otpControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isFocused ? AppColors.primary : AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                if (mounted) setState(() {});
                if (value.isNotEmpty) {
                  if (index < 7) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                  }
                } else {
                  if (index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                }
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Security/Verification Graphic Header
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.12),
                          blurRadius: 24,
                          spreadRadius: 6,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Screen Title
                Text(
                  'Verification',
                  style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description with Highlighted Email Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      viewModel.emailController.text,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 8-digit verification code sent to your email to reset your password.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Layout for 8 digits: Split into 4 and 4 with visual separator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // First 4 digits
                    ...List.generate(4, (index) {
                      return Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: buildDigitField(index),
                        ),
                      );
                    }),
                    // Separator dash/dot
                    Container(
                      width: 8,
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    // Last 4 digits
                    ...List.generate(4, (index) {
                      return Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: buildDigitField(index + 4),
                        ),
                      );
                    }),
                  ],
                ),

                // Custom Alert Error Banner if code verification failed
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage!,
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.red.shade800, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // Verify Button
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
                const SizedBox(height: 24),

                // Resend Code Trigger with Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: AppTextStyles.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: (viewModel.isLoading || _cooldownSeconds > 0)
                          ? null
                          : () async {
                              await viewModel.sendOtp(context);
                              _startCooldown();
                            },
                      child: Text(
                        _cooldownSeconds > 0
                            ? "Resend in ${_cooldownSeconds}s"
                            : "Resend Code",
                        style: AppTextStyles.link.copyWith(
                          color: (viewModel.isLoading || _cooldownSeconds > 0)
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: _cooldownSeconds > 0
                              ? TextDecoration.none
                              : TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
