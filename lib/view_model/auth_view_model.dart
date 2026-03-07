import 'package:collab_bot/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepositoryImpl(AuthService(Supabase.instance.client));

  bool isLoading = false;
  String? successMessage;
  String? errorMessage;

  // ✅ Add current user
  UserModel? currentUser;

  Future<void> signUp(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.signUp(
        email: email,
        password: password,
        fullName: 'New User',
        role: 'user',
      );
      errorMessage = null; // No error
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
      await _repository.signIn(email: email, password: password);
      errorMessage = null;
      // Set to null as signIn doesn't directly return a user model
      currentUser = null; 
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
}

