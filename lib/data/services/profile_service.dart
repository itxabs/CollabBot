import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_models.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  // Fetch User Profile
  Future<UserProfile> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  // Fetch User Skills
  Future<List<UserSkill>> getSkills(String userId) async {
    try {
      final response = await _supabase
          .from('user_skills')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => UserSkill.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load skills: $e');
    }
  }

  // Fetch Skill Levels
  Future<List<SkillLevel>> getSkillLevels() async {
    try {
      final response = await _supabase
          .from('skill_levels')
          .select()
          .order('id', ascending: true);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => SkillLevel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load skill levels: $e');
    }
  }

  // Add User Skill
  Future<void> addUserSkill(String userId, String skillName, String skillLevelId) async {
    try {
      await _supabase.from('user_skills').insert({
        'user_id': userId,
        'skill_name': skillName,
        'skill_level_id': skillLevelId,
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add skill: $e');
    }
  }

  // Add User Experience
  Future<void> addExperience({
    required String userId,
    required String organization,
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      await _supabase.from('experiences').insert({
        'user_id': userId,
        'organization': organization,
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add experience: $e');
    }
  }

  // Fetch User Experiences
  Future<List<Experience>> getExperiences(String userId) async {
    try {
      final response = await _supabase
          .from('experiences')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false); // Most recent first

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Experience.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load experiences: $e');
    }
  }
  // Verify Skill
  Future<void> verifySkill(String userSkillId) async {
    try {
      await _supabase
          .from('user_skills')
          .update({'is_verified': true})
          .eq('id', userSkillId);
    } catch (e) {
      throw Exception('Failed to verify skill: $e');
    }
  }
}
