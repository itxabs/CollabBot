import '../services/auth_service.dart';

abstract class AuthRepository {
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  });

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> resetPasswordForEmail(String email);

  Future<void> verifyOTP({
    required String email,
    required String token,
  });

  Future<void> updatePassword(String newPassword);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _authService.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      await _authService.verifyOTP(email: email, token: token);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }
}
