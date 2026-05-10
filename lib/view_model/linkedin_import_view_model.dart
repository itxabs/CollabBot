import 'package:flutter/material.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LinkedInImportViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  LinkedInImportViewModel()
      : _profileRepository = ProfileRepositoryImpl(
          ProfileService(Supabase.instance.client),
        );

  bool _isLoading = false;
  String? _errorMessage;
  
  List<String> _extractedSkills = [];
  List<Experience> _extractedExperiences = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get extractedSkills => _extractedSkills;
  List<Experience> get extractedExperiences => _extractedExperiences;

  void setExtractedData(List<String> skills, List<Experience> experiences) {
    _extractedSkills = skills;
    _extractedExperiences = experiences;
    notifyListeners();
  }

  void removeSkill(int index) {
    _extractedSkills.removeAt(index);
    notifyListeners();
  }

  void removeExperience(int index) {
    _extractedExperiences.removeAt(index);
    notifyListeners();
  }

  Future<void> saveImportedData(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Get a default Skill Level ID
      final levels = await _profileRepository.getSkillLevels();
      final defaultLevelId = levels.isNotEmpty ? levels.first.id : '';

      // 2. Save Skills
      for (final skillName in _extractedSkills) {
        await _profileRepository.addUserSkill(user.id, skillName, defaultLevelId);
      }

      // 3. Save Experiences
      for (final exp in _extractedExperiences) {
        await _profileRepository.addExperience(
          userId: user.id,
          organization: exp.organization,
          title: exp.title,
          description: exp.description,
          startDate: exp.startDate,
          endDate: exp.endDate,
        );
      }

      if (context.mounted) {
        // Return to the previous screen (Setup or Profile) with success
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/setup' || route.settings.name == '/profile');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LinkedIn profile data imported!')),
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
