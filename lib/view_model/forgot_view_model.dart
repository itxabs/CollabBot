import 'package:flutter/material.dart';
import '../core/constants/routes.dart';

class ForgotViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> sendResetLink(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();

    // Navigate to OTP or Login 
    // Assuming OTP flow for now based on task list
    if (context.mounted) {
       // Ideally pass email as argument
      Navigator.pushNamed(context, AppRoutes.login); // Or OTP
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent to your email')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
