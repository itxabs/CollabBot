import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/routes.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';

enum ForgotPasswordStep { emailInput, otpInput, passwordUpdate }

class ForgetPassViewModel extends ChangeNotifier {
  // Dependency Injection
  final AuthRepository _authRepository = AuthRepositoryImpl(
    AuthService(Supabase.instance.client),
  );

  ForgotPasswordStep _currentStep = ForgotPasswordStep.emailInput;
  ForgotPasswordStep get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final List<TextEditingController> otpControllers = List.generate(8, (_) => TextEditingController());
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();

  // Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Step 1: Send OTP
  Future<void> sendOtp(BuildContext context) async {
    if (!emailFormKey.currentState!.validate()) return;
    
    _setLoading(true);
    _setError(null);

    try {
      await _authRepository.resetPasswordForEmail(emailController.text.trim());
      _currentStep = ForgotPasswordStep.otpInput;
      notifyListeners();
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email')));
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Step 2: Verify OTP
  Future<void> verifyOtp(BuildContext context) async {
    String otp = otpControllers.map((c) => c.text).join();
    if (otp.length != 8) {
      _setError('Please enter a valid 8-digit OTP');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _authRepository.verifyOTP(email: emailController.text.trim(), token: otp);
      _currentStep = ForgotPasswordStep.passwordUpdate;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Step 3: Update Password
  Future<void> updatePassword(BuildContext context) async {
    if (!passwordFormKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      _setError('Passwords do not match');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _authRepository.updatePassword(newPasswordController.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  void onOtpDigitEntered(int index, String value, BuildContext context) {
      if (value.isNotEmpty && index < 7) {
        FocusScope.of(context).nextFocus();
      } else if (value.isEmpty && index > 0) {
        FocusScope.of(context).previousFocus();
      }
  }

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    for (var c in otpControllers) {c.dispose();} // Fix: Dispose OTP controllers
    super.dispose();
  }
}
