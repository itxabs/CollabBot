import 'package:collab_bot/core/widgets/app_button.dart';
import 'package:collab_bot/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    // Controllers for email & password
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/collab_bot_logo.png',
                  height: 120,
                  width: 120,
                ),
                // App Logo / Title
                const Text(
                  "CollabBot",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Login to continue",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Login Card
                Column(
                  children: [
                    AppInputField(
                      controller: emailController,
                      icon: Icons.email_outlined,
                      hint: "Institutional Email",
                    ),
                    const SizedBox(height: 16),
                    AppInputField(
                      controller: passwordController,
                      icon: Icons.lock_outline,
                      hint: "Password",
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    AppButton(
                      text: "Login",
                      isLoading: authVM.isLoading,

                      onPressed: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text;

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all fields"),
                            ),
                          );
                          return;
                        }

                        await authVM.login(email, password);

                        if (authVM.errorMessage == null) {
                          Navigator.pushReplacementNamed(context, '/main-navigation');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(authVM.errorMessage!)),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forget-pass');
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0xFF323743),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Signup Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Color(0xFF9095A1)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Sign Up",
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
