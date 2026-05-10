import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';

class SocialMediaViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  SocialMediaViewModel()
      : _profileRepository = ProfileRepositoryImpl(
          ProfileService(Supabase.instance.client),
        );

  List<UserSocialLink> _socialLinks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Form State
  String? _selectedPlatform;
  final TextEditingController urlController = TextEditingController();

  // Getters
  List<UserSocialLink> get socialLinks => _socialLinks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedPlatform => _selectedPlatform;

  set selectedPlatform(String? value) {
    _selectedPlatform = value;
    notifyListeners();
  }

  final List<Map<String, dynamic>> platforms = [
    {'id': 'linkedin', 'name': 'LinkedIn'},
    {'id': 'github', 'name': 'GitHub'},
    {'id': 'facebook', 'name': 'Facebook'},
    {'id': 'twitter', 'name': 'X (Twitter)'},
    {'id': 'instagram', 'name': 'Instagram'},
    {'id': 'website', 'name': 'Website'},
  ];

  Future<void> loadSocialLinks() async {
    final user = Supabase.instance.client.auth.currentUser;
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

  Future<void> addSocialLink(BuildContext context) async {
    if (_selectedPlatform == null || urlController.text.isEmpty) {
      _errorMessage = 'Platform and URL are required';
      notifyListeners();
      return;
    }

    final String url = urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _errorMessage = 'this is not the link please add link only.';
      notifyListeners();
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.addSocialLink(
        user.id,
        _selectedPlatform!,
        urlController.text,
      );
      
      // Reset form
      _selectedPlatform = null;
      urlController.clear();
      
      await loadSocialLinks();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Social link added successfully')),
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSocialLink(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _profileRepository.deleteSocialLink(id);
      await loadSocialLinks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}
