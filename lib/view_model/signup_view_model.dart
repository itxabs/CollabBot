import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import '../core/constants/routes.dart';
import 'package:provider/provider.dart';
import 'auth_view_model.dart';


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

      // Success
      if (context.mounted) {
        _isLoading = false;
        notifyListeners(); // Notify first
        
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        await authVM.initializeCurrentUser();

        // Redirect decisively to Home
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created! Welcome to Home.')),
        );
      }

    } catch (e) {
      if (context.mounted) {
        final alreadyExists = e.toString().contains('user_already_exists');
        _isLoading = false;
        _errorMessage = alreadyExists ? 'Welcome back! Profile Updated.' : e.toString().replaceAll('Exception: ', '');
        
        notifyListeners(); 

        if (alreadyExists) {
          // Even if they exist, navigate them to Home now that we updated their role
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
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
