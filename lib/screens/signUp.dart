import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    // Controllers for input fields
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A5AE0),
              Color(0xFF4D8DFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sign up to get started",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField(
                          controller: fullNameController,
                          icon: Icons.person_outline,
                          hint: "Full Name",
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          controller: emailController,
                          icon: Icons.email_outlined,
                          hint: "Email",
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          controller: passwordController,
                          icon: Icons.lock_outline,
                          hint: "Password",
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          controller: confirmPasswordController,
                          icon: Icons.lock_outline,
                          hint: "Confirm Password",
                          isPassword: true,
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authVM.isLoading
                                ? null
                                : () async {
                                    final fullName = fullNameController.text.trim();
                                    final email = emailController.text.trim();
                                    final password = passwordController.text;
                                    final confirmPassword = confirmPasswordController.text;

                                    // Basic validation
                                    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please fill all fields")),
                                      );
                                      return;
                                    }

                                    if (password != confirmPassword) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Passwords do not match")),
                                      );
                                      return;
                                    }

                                    // Call signup
                                    await authVM.signUp(email, password);

                                    if (authVM.errorMessage == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Signup Successful!")),
                                      );
                                      // Navigate to home or login
                                      Navigator.pushReplacementNamed(context, '/login');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(authVM.errorMessage!)),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A5AE0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: authVM.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF6A5AE0)),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
