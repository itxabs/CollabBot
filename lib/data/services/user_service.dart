import 'package:collab_bot/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final supabase = Supabase.instance.client;

<<<<<<< HEAD
  /// Fetch user by ID ......
=======
  /// Fetch user by ID
>>>>>>> main
  Future<UserModel?> fetchUser(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // <- updated method

      if (response == null) return null;

<<<<<<< HEAD
      return UserModel.fromMap(response);
=======
      return UserModel.fromMap(response as Map<String, dynamic>);
>>>>>>> main
    } catch (e) {
      throw Exception("Failed to fetch user: $e");
    }
  }
}
