import 'dart:io';
import '../models/profile_models.dart';
import '../services/profile_service.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile(String userId);
  Future<List<UserSkill>> getUserSkills(String userId);
  Future<List<Experience>> getUserExperiences(String userId);
  Future<List<Education>> getUserEducation(String userId);
  
  Future<List<SkillLevel>> getSkillLevels();
  Future<void> addUserSkill(String userId, String skillName, String skillLevelId);
  Future<void> deleteUserSkill(String userId, String userSkillId);
  Future<void> addLeaderboardPoints(String userId, int points, String actionType);
  
  Future<void> addExperience({
    required String userId,
    required String organization,
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
  });
  Future<void> deleteExperience(String userId, String experienceId);

  Future<void> addEducation({
    required String userId,
    required String institution,
    String? degree,
    String? fieldOfStudy,
    int? startYear,
    int? endYear,
  });
  Future<void> deleteEducation(String userId, String educationId);
  
  Future<void> verifySkill(String userSkillId);
  Future<void> updateProfile(String userId, {String? name, String? email, DateTime? dob});
  Future<void> uploadProfilePicture(String userId, File file);
  
  Future<List<UserSocialLink>> getUserSocialLinks(String userId);
  Future<void> addSocialLink(String userId, String platform, String url);
  Future<void> deleteSocialLink(String id);
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
  Future<List<Education>> getUserEducation(String userId) async {
    return await _service.getEducation(userId);
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
  Future<void> deleteUserSkill(String userId, String userSkillId) async {
    return await _service.deleteUserSkill(userId, userSkillId);
  }

  @override
  Future<void> addLeaderboardPoints(String userId, int points, String actionType) async {
    return await _service.addLeaderboardPoints(userId, points, actionType);
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
  Future<void> deleteExperience(String userId, String experienceId) async {
    return await _service.deleteExperience(userId, experienceId);
  }

  @override
  Future<void> addEducation({
    required String userId,
    required String institution,
    String? degree,
    String? fieldOfStudy,
    int? startYear,
    int? endYear,
  }) async {
    return await _service.addEducation(
      userId: userId,
      institution: institution,
      degree: degree,
      fieldOfStudy: fieldOfStudy,
      startYear: startYear,
      endYear: endYear,
    );
  }

  @override
  Future<void> deleteEducation(String userId, String educationId) async {
    return await _service.deleteEducation(userId, educationId);
  }

  @override
  Future<void> verifySkill(String userSkillId) async {
    return await _service.verifySkill(userSkillId);
  }

  @override
  Future<void> updateProfile(String userId, {String? name, String? email, DateTime? dob}) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['full_name'] = name;
    if (email != null) data['email'] = email;
    if (dob != null) data['dob'] = dob.toIso8601String().split('T')[0];
    
    if (data.isNotEmpty) {
      await _service.updateProfile(userId, data);
    }
  }

  @override
  Future<void> uploadProfilePicture(String userId, File file) async {
    final publicUrl = await _service.uploadAvatar(userId, file);
    await _service.updateAvatarUrl(userId, publicUrl);
  }

  @override
  Future<List<UserSocialLink>> getUserSocialLinks(String userId) async {
    return await _service.getSocialLinks(userId);
  }

  @override
  Future<void> addSocialLink(String userId, String platform, String url) async {
    return await _service.addSocialLink(userId, platform, url);
  }

  @override
  Future<void> deleteSocialLink(String id) async {
    return await _service.deleteSocialLink(id);
  }
}
