import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/routes.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import 'auth_view_model.dart';
import '../core/utils/error_handler.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepositoryImpl(
    AuthService(Supabase.instance.client),
  );

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> login(BuildContext context, AuthViewModel authViewModel) async {
    if (!formKey.currentState!.validate()) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await authViewModel.fetchUserProfile(session.user.id);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
      }

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.getFriendlyMessage(e);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
