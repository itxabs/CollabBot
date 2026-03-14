import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      
      // Refresh list
      await loadData();
      
      if (context.mounted) {
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill added successfully')),
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
