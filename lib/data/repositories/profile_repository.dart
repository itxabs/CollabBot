import '../models/profile_models.dart';
import '../services/profile_service.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile(String userId);
  Future<List<UserSkill>> getUserSkills(String userId);
  Future<List<Experience>> getUserExperiences(String userId);
  
  Future<List<SkillLevel>> getSkillLevels();
  Future<void> addUserSkill(String userId, String skillName, String skillLevelId);
  
  Future<void> addExperience({
    required String userId,
    required String organization,
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
  });
  
  Future<void> verifySkill(String userSkillId);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileService _service;

  ProfileRepositoryImpl(this._service);

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    return await _service.getProfile(userId);
  }

  @override
  Future<List<UserSkill>> getUserSkills(String userId) async {
    return await _service.getSkills(userId);
  }

  @override
  Future<List<Experience>> getUserExperiences(String userId) async {
    return await _service.getExperiences(userId);
  }

  @override
  Future<List<SkillLevel>> getSkillLevels() async {
    return await _service.getSkillLevels();
  }

  @override
  Future<void> addUserSkill(String userId, String skillName, String skillLevelId) async {
    return await _service.addUserSkill(userId, skillName, skillLevelId);
  }

  @override
  Future<void> addExperience({
    required String userId,
    required String organization,
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    return await _service.addExperience(
      userId: userId,
      organization: organization,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> verifySkill(String userSkillId) async {
    return await _service.verifySkill(userSkillId);
  }
}

