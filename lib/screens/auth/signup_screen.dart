import 'package:collab_bot/core/widgets/app_button.dart';
import 'package:collab_bot/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    // Controllers for input fields
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Create Your \nCollabBot Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Join a thriving community of university students and alumni.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Card
                Column(
                  children: [
                    AppInputField(
                      controller: fullNameController,
                      icon: Icons.person_outline,
                      hint: "Full Name",
                    ),
                    const SizedBox(height: 16),
                    AppInputField(
                      controller: emailController,
                      icon: Icons.email_outlined,
                      hint: "Institue Email",
                    ),
                    const SizedBox(height: 16),
                    AppInputField(
                      controller: passwordController,
                      icon: Icons.lock_outline,
                      hint: "Password",
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    AppInputField(
                      controller: confirmPasswordController,
                      icon: Icons.lock_outline,
                      hint: "Confirm Password",
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    AppButton(
                      text: "Sign Up",
                      isLoading: authVM.isLoading,
                      onPressed: () async {
                        final fullName = fullNameController.text.trim();
                        final email = emailController.text.trim();
                        final password = passwordController.text;
                        final confirmPassword = confirmPasswordController.text;

                        if (fullName.isEmpty ||
                            email.isEmpty ||
                            password.isEmpty ||
                            confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all fields"),
                            ),
                          );
                          return;
                        }

                        if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Passwords do not match"),
                            ),
                          );
                          return;
                        }

                        await authVM.signUp(email, password);

                        if (authVM.errorMessage == null) {
                          Navigator.pushReplacementNamed(context, '/login');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(authVM.errorMessage!)),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Color(0xFF9095A1)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF28a745),
                          fontWeight: FontWeight.bold,
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
