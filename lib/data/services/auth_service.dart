import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    String? userId;

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      userId = response.user?.id;
    } catch (e) {
      if (e.toString().contains('user_already_exists') ||
          e.toString().contains('422')) {
        try {
          final signInRes = await signIn(email: email, password: password);
          userId = signInRes.user?.id;
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (userId == null) throw Exception('Signup failed: No user ID retrieved');

    try {
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final existing = await _supabase
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (existing != null) {
          final existingId = existing['id'] as String;
          await _supabase
              .from('users')
              .update({
                'full_name': fullName,
                'role': role,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existingId);
        }
      } else {
        rethrow;
      }
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
