import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class ExperienceViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  // State
  List<Experience> _experiences = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Experience> get experiences => _experiences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ExperienceViewModel()
      : _profileRepository = ProfileRepositoryImpl(
          ProfileService(Supabase.instance.client),
        );

  // Load experiences
  Future<void> loadExperiences() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _experiences = await _profileRepository.getUserExperiences(currentUser.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new experience
  Future<void> addExperience(
    BuildContext context, {
    required String organization,
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.addExperience(
        userId: currentUser.id,
        organization: organization,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
      );
      await _profileRepository.addLeaderboardPoints(
        currentUser.id,
        10,
        'add_experience',
      );

      // Refresh list
      await loadExperiences();

      if (context.mounted) {
        Navigator.pop(context); // Go back to list
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
                      '+10 Points Earned 🎉 Experience Added Successfully',
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

  Future<void> deleteExperience(BuildContext context, String experienceId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.deleteExperience(currentUser.id, experienceId);
      await loadExperiences();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('Experience deleted successfully')),
          );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
