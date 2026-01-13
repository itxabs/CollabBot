import 'package:collab_bot/core/widgets/app_text_field.dart';
import 'package:collab_bot/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_button.dart';

class ForgetPass extends StatelessWidget {
  ForgetPass({super.key});

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFAFAFA),
        elevation: 2,
        iconTheme: IconThemeData(color: Color(0xFF28a745)),
      ),
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              /// Heading
              const Text(
                "Forget Password?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              /// Description
              const Text(
                "Enter your institute email to receive a password reset link.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 32),

              /// Email Input Field (Reusable)
              AppInputField(
                controller: emailController,
                icon: Icons.email_outlined,
                hint: "Institute Email",
              ),

              const SizedBox(height: 32),

              /// Reset Button (Reusable)
              AppButton(
                text: authVM.isLoading ? "Sending..." : "Send Reset Link",
                onPressed: authVM.isLoading
                    ? null
                    : () async {
                        await context.read<AuthViewModel>().forgetPassword(
                          emailController.text.trim(),
                        );

                        // Show SnackBar messages
                        if (authVM.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authVM.errorMessage!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (authVM.successMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authVM.successMessage!),
                              backgroundColor: Colors.green,
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
