import 'package:collab_bot/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final supabase = Supabase.instance.client;

  /// Fetch user by ID
  Future<UserModel?> fetchUser(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select(
            'id, email, full_name, role, reputation, avatar_url, dob, created_at',
          )
          .eq('id', userId)
          .maybeSingle(); // <- updated method

      if (response == null) return null;

      return UserModel.fromMap(response);
    } catch (e) {
      throw Exception("Failed to fetch user: $e");
    }
  }

  /// Fetch user's total points from leaderboard_scores_summary view or log table
  Future<int> fetchUserLifetimePoints(String userId) async {
    try {
      // 1. Try fetching from the summary view first
      final summaryRes = await supabase
          .from('leaderboard_scores_summary')
          .select('lifetime_score')
          .eq('user_id', userId)
          .maybeSingle();

      if (summaryRes != null) {
        return _toInt(summaryRes['lifetime_score']);
      }

      // 2. Fallback: Aggregate manually from the log table if view is missing or user has no entry in view
      final logRes = await supabase
          .from('leaderboard_scores_log')
          .select('points')
          .eq('user_id', userId);

      final List rows = logRes as List;
      int total = 0;
      for (final row in rows) {
        total += _toInt(row['points']);
      }
      return total;
    } catch (e) {
      // Log error but return 0 to avoid crashing the UI
      return 0;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
