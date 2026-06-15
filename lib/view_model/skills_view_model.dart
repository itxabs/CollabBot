import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';

class SkillsViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  // State
  List<UserSkill> _skills = [];
  List<SkillLevel> _levels = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<UserSkill> get skills => _skills;
  List<SkillLevel> get levels => _levels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SkillsViewModel()
      : _profileRepository = ProfileRepositoryImpl(
          ProfileService(Supabase.instance.client),
        );

  // Load skills and levels
  Future<void> loadData() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _profileRepository.getUserSkills(currentUser.id),
        _profileRepository.getSkillLevels(),
      ]);

      _skills = results[0] as List<UserSkill>;
      _levels = results[1] as List<SkillLevel>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new skill
  Future<void> addSkill(BuildContext context, {required String name, required String levelId}) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.addUserSkill(currentUser.id, name, levelId);
      await _profileRepository.addLeaderboardPoints(currentUser.id, 5, 'add_skill');
      
      // Refresh list
      await loadData();
      
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
                      '+5 Points Earned 🎉 Skill Added Successfully',
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

  Future<void> deleteSkill(BuildContext context, String userSkillId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.deleteUserSkill(currentUser.id, userSkillId);
      await loadData();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('Skill deleted successfully')),
          );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get level name from ID
  String getLevelName(String levelId) {
    try {
      return _levels.firstWhere((l) => l.id == levelId).name;
    } catch (e) {
      return 'Unknown';
    }
  }
}
