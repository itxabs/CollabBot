import 'package:collab_bot/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepositoryImpl(
    AuthService(Supabase.instance.client),
  );

  bool isLoading = false;
  String? successMessage;
  String? errorMessage;

  // ✅ Add current user
  UserModel? currentUser;

  AuthViewModel() {
    initializeCurrentUser();
  }

  Future<void> initializeCurrentUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
       currentUser = null;
       notifyListeners();
       return;
    }
    await fetchUserProfile(session.user.id);
  }


  Future<void> fetchUserProfile(String userId) async {
    try {
      final userData = await _repository.getUserProfile(userId);
      if (userData != null) {
        currentUser = UserModel.fromMap(userData);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    notifyListeners();
  }


  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      
      // Fetch profile immediately after signup so currentUser is not null
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await fetchUserProfile(session.user.id);
      }
      
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.signIn(
        email: email,
        password: password,
      );
      
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await fetchUserProfile(session.user.id);
      }
      
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      currentUser = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<void> forgetPassword(String email) async {
    if (email.isEmpty) {
      errorMessage = "Email cannot be blank";
      successMessage = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    successMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.resetPasswordForEmail(email);
      successMessage = "If this email exists, a reset link was sent.";
    } catch (e) {
      errorMessage = "Something went wrong. Try again.";
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    currentUser = null;
    notifyListeners();
  }
}



