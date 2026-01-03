

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

Future<AuthResponse> signUp(String email, String password) async {
  try {
    final response = await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
    );
    print("User: ${response.user}");
    return response;
  } catch (e) {
    print("Signup Exception: $e");
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


}
