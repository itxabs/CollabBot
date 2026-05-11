import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/routes.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';
import 'auth_view_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  // State
  UserProfile? _user;
  List<UserSkill> _skills = [];
  List<Experience> _experiences = [];
  List<UserSocialLink> _socialLinks = [];

  final String? targetUserId;

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  // Getters
  bool get isOwnProfile => targetUserId == null || targetUserId == Supabase.instance.client.auth.currentUser?.id;

  UserProfile? get user => _user;
  List<UserSkill> get skills => _skills;
  List<Experience> get experiences => _experiences;
  List<UserSocialLink> get socialLinks => _socialLinks;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  // Computed Properties for UI
  String get joinedDateString {
    if (_user == null) return '';
    final now = DateTime.now();
    final joinDate = _user!.createdAt;
    final difference = now.difference(joinDate);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Joined $years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Joined $months month${months > 1 ? 's' : ''} ago';
    } else {
      return 'Joined recently';
    }
  }

  ProfileViewModel({this.targetUserId})
    : _profileRepository = ProfileRepositoryImpl(
        ProfileService(Supabase.instance.client),
      ) {
    _loadData();
  }


  Future<void> refresh() => _loadData();

  Future<void> _loadData() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = targetUserId ?? currentUser.id;


      // Parallel fetching for performance
      final results = await Future.wait([
        _profileRepository.getUserProfile(userId),
        _profileRepository.getUserSkills(userId),
        _profileRepository.getUserExperiences(userId),
        _profileRepository.getUserSocialLinks(userId),
      ]);

      _user = results[0] as UserProfile;
      _skills = results[1] as List<UserSkill>;
      _experiences = results[2] as List<Experience>;
      _socialLinks = results[3] as List<UserSocialLink>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout(BuildContext context, AuthViewModel authViewModel) async {
    await authViewModel.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  // Image Picking and Upload
  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _isUploading = true;
      notifyListeners();

      final File file = File(image.path);
      await _profileRepository.uploadProfilePicture(user.id, file);

      // Refresh data
      await _loadData();
    } catch (e) {
      _errorMessage = 'Failed to upload profile picture: $e';
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}
