import '../data_layer/auth_repository.dart';
import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool isLoading = false;
  String? errorMessage;

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

  Future<void> login(String email, String password) async {
  isLoading = true;
  notifyListeners();

  try {
    final response = await _repository.loginUser(email, password);
    if (!response) {
      errorMessage = "Login failed. Check credentials.";
    } else {
      errorMessage = null;
    }
  } catch (e) {
    errorMessage = e.toString();
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

}
