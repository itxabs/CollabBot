import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import '../core/constants/routes.dart';
import '../core/utils/error_handler.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  // Constructor with dependency injection (can be simplified if using get_it or direct instantiation for this task)
  SignupViewModel() : _authRepository = AuthRepositoryImpl(AuthService(Supabase.instance.client));

  // State
  int _currentStep = 1;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Form Controllers (Step 1)
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Role Selection (Step 2)
  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  void selectRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  // Navigation / Logic
  void nextStep() {
    // Validate Step 1
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _errorMessage = 'Please fill all fields';
      notifyListeners();
      return;
    }
    
    // Basic email validation
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
    // Validate Step 2
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

      if (!context.mounted) return;

      // Update AuthViewModel with new user
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.initializeCurrentUser();

      // Save logged-in state to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
      } catch (e) {
        debugPrint('Error setting signup login preference: $e');
      }

      // Success
      if (context.mounted) {
        _isLoading = false;
        notifyListeners();
        // Go to Profile Setup
        Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please complete your profile.')),
        );
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = ErrorHandler.getFriendlyMessage(e);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Signup failed'),
            backgroundColor: Colors.red,
          ),
        );
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
