import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

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

  void clearForm() {
    _selectedPlatform = null;
    urlController.clear();
    _errorMessage = null;
    notifyListeners();
  }

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
      
      await _profileRepository.addLeaderboardPoints(user.id, 3, 'add_social_link');
      
      // Reset form
      _selectedPlatform = null;
      urlController.clear();
      
      await loadSocialLinks();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration_outlined, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '+3 Points Earned 🎉 Link Added Successfully',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
