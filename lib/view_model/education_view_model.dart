import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class EducationViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  // State
  List<Education> _education = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Education> get education => _education;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EducationViewModel()
      : _profileRepository = ProfileRepositoryImpl(
          ProfileService(Supabase.instance.client),
        );

  // Load education
  Future<void> loadEducation() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _education = await _profileRepository.getUserEducation(currentUser.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new education
  Future<void> addEducation(
    BuildContext context, {
    required String institution,
    String? degree,
    String? fieldOfStudy,
    int? startYear,
    int? endYear,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.addEducation(
        userId: currentUser.id,
        institution: institution,
        degree: degree,
        fieldOfStudy: fieldOfStudy,
        startYear: startYear,
        endYear: endYear,
      );
      await _profileRepository.addLeaderboardPoints(
        currentUser.id,
        10,
        'add_education',
      );

      // Refresh list
      await loadEducation();

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
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration_outlined, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '+10 Points Earned 🎉 Education Added Successfully',
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

  Future<void> deleteEducation(BuildContext context, String educationId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.deleteEducation(currentUser.id, educationId);
      await loadEducation();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('Education deleted successfully')),
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
