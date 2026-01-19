import 'package:collab_bot/data/models/user_model.dart';

import '../data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool isLoading = false;
  String? successMessage;
  String? errorMessage;

  // ✅ Add current user
  UserModel? currentUser;

  Future<void> signUp(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      bool success = await _repository.signUpUser(email, password);
      if (!success) {
        errorMessage = "Signup failed!";
      } else {
        errorMessage = null; // No error
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> login(String email, String password) async {
  //   isLoading = true;
  //   notifyListeners();

  //   try {
  //     // ✅ Repository should return the UserModel on success
  //     final user = await _repository.loginUser(email, password);

  //     if (user == null) {
  //       errorMessage = "Login failed. Check credentials.";
  //       currentUser = null;
  //     } else {
  //       currentUser = user; // Save logged-in user
  //       errorMessage = null;
  //     }
  //   } catch (e) {
  //     errorMessage = e.toString();
  //     currentUser = null;
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

Future<void> login(String email, String password) async {
  isLoading = true;
  notifyListeners();

  try {
    final user = await _repository.loginUser(email, password);

    if (user == null) {
      errorMessage = "Login failed. Check credentials.";
      currentUser = null;
    } else {
      currentUser = user; // ✅ Type matches UserModel?
      errorMessage = null;
    }
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
      await _repository.forgetPassword(email);
      successMessage = "If this email exists, a reset link was sent.";
    } catch (e) {
      errorMessage = "Something went wrong. Try again.";
    }

    isLoading = false;
    notifyListeners();
  }
}

