import 'package:flutter/material.dart';
import '../core/constants/routes.dart';

class UserProfile {
  final String name;
  final String email;
  final String role;
  final int points;

  UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.points,
  });
}

class ProfileViewModel extends ChangeNotifier {
  UserProfile? _user;
  UserProfile? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get errorMessage => null;

  ProfileViewModel() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _user = UserProfile(
      name: 'Abdul',
      email: 'abdul@example.com',
      role: 'Flutter Developer',
      points: 1250,
    );

    _isLoading = false;
    notifyListeners();
  }

  void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}
