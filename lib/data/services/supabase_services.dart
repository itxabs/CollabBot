// import 'package:supabase_flutter/supabase_flutter.dart';

// class SupabaseService {
//   static final SupabaseClient client = Supabase.instance.client;

//   Future<AuthResponse> signUp(String email, String password) async {
//     try {
//       final response = await SupabaseService.client.auth.signUp(
//         email: email,
//         password: password,
//       );
//       print("User: ${response.user}");
//       return response;
//     } catch (e) {
//       print("Signup Exception: $e");
//       rethrow;
//     }
//   }

//   Future<AuthResponse> login(String email, String password) async {
//     try {
//       final response = await client.auth.signInWithPassword(
//         email: email,
//         password: password,
//       );
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> sendResetPasswordEmail(String email) async {
//     try {
//       await client.auth.resetPasswordForEmail(email);
//     } catch (e) {
//       rethrow;
//     }
//   }
// }

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendResetPasswordEmail(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// ✅ Fetch user from Supabase 'users' table
  Future<UserModel?> getUserById(String userId) async {
    final data = await client
        .from('users')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromMap(data as Map<String, dynamic>);
  }
}
