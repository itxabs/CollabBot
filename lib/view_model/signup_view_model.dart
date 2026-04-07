import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import '../core/constants/routes.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  SignupViewModel()
    : _authRepository = AuthRepositoryImpl(
        AuthService(Supabase.instance.client),
      );

  int _currentStep = 1;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  void selectRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void nextStep() {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _errorMessage = 'Please fill all fields';
      notifyListeners();
      return;
    }

    if (!emailController.text.contains('@')) {
      _errorMessage = 'Invalid email address';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _currentStep = 2;
    notifyListeners();
  }

  void previousStep() {
    _currentStep = 1;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signUp(BuildContext context) async {
    if (_selectedRole == null) {
      _errorMessage = 'Please select a role';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text.trim(),
        role: _selectedRole!,
      );

      if (context.mounted) {
        _isLoading = false;
        notifyListeners();

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account Created! Please login to continue.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final alreadyExists = e.toString().contains('user_already_exists');
        _isLoading = false;
        _errorMessage = alreadyExists
            ? 'Welcome back! Profile Updated.'
            : e.toString().replaceAll('Exception: ', '');

        notifyListeners();

        if (alreadyExists) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
