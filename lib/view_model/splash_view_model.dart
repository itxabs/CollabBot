import 'package:flutter/foundation.dart';
import '../core/constants/routes.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<String> init() async {
    // Simulate initialization (e.g., checking tokens, loading configs)
    await Future.delayed(const Duration(seconds: 3));
    
    _isLoading = false;
    notifyListeners();
    
    // logic to determine where to go: 
    // if authenticated -> home
    // else if first time -> onboarding
    // else -> login
    
    // For now, default to Onboarding as per flow
    return AppRoutes.onboarding; 
  }
}
