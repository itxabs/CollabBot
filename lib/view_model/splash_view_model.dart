import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/routes.dart';
import 'auth_view_model.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<String> init(AuthViewModel authViewModel) async {
    // Simulate initialization (e.g., checking tokens, loading configs)
    await Future.delayed(const Duration(seconds: 3));
    
    _isLoading = false;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    
    // Check if first time onboarding is needed
    final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    if (!seenOnboarding) {
      return AppRoutes.onboarding;
    }
    
    // Check if user is logged in
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final session = Supabase.instance.client.auth.currentSession;
    
    if (isLoggedIn && session != null) {
      try {
        await authViewModel.initializeCurrentUser();
        if (authViewModel.currentUser != null) {
          return AppRoutes.home;
        }
      } catch (e) {
        debugPrint('Error initializing user profile on startup: $e');
      }
    }
    
    // If not logged in, or session is expired/missing, reset flag to be safe
    if (isLoggedIn) {
      await prefs.setBool('is_logged_in', false);
    }
    
    return AppRoutes.login;
  }
}
