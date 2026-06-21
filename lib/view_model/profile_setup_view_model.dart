import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/routes.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';
import 'auth_view_model.dart';

class ProfileSetupViewModel extends ChangeNotifier {
  late final ProfileRepository _profileRepository;
  final SupabaseClient _supabase = Supabase.instance.client;

  ProfileSetupViewModel() {
    _profileRepository = ProfileRepositoryImpl(
      ProfileService(_supabase),
    );
  }

  UserProfile? _user;
  String? _avatarUrl;
  List<UserSocialLink> _socialLinks = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  // Getters
  String? get avatarUrl => _avatarUrl ?? _user?.avatarUrl;
  List<UserSocialLink> get socialLinks => _socialLinks;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  String get initials {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'U';
    final name = user.userMetadata?['full_name'] as String? ?? 'User';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      _isUploading = true;
      _errorMessage = null;
      notifyListeners();

      final File file = File(image.path);
      
      // Defensive check (though late final should prevent this)
      final repo = _profileRepository;
      
      await repo.uploadProfilePicture(user.id, file);

      // Fetch the updated profile to get the new avatarUrl
      final updatedProfile = await repo.getUserProfile(user.id);
      _avatarUrl = updatedProfile.avatarUrl;
      
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      _errorMessage = 'Failed to upload profile picture: ${e.toString()}';
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> loadSocialLinks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _socialLinks = await _profileRepository.getUserSocialLinks(user.id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeProfile(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update AuthViewModel with new user info
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.initializeCurrentUser();

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.profileComplete);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
