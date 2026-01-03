import '../services/supabase_services.dart';

class AuthRepository {
  final SupabaseService _service = SupabaseService();

  Future<bool> signUpUser(String email, String password) async {
    try {
      final response = await _service.signUp(email, password);
      if (response.user != null) {
        return true; // Signup success
      } else {
        return false; // Something went wrong
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await _service.login(
        email,
        password,
      ); 
      return response.user != null;
    } catch (e) {
      print("Login Exception: $e");
      return false;
    }
  }
}
