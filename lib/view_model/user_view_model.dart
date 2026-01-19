import 'package:collab_bot/data/models/user_model.dart';
import 'package:flutter/material.dart';
import '../data/repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadUser(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _repository.getUserById(userId);
    } catch (e) {
      errorMessage = "Failed to load user";
    }

    isLoading = false;
    notifyListeners();
  }
}
