class ErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    if (error == null) return 'Something went wrong';
    
    final errorStr = error.toString().toLowerCase();

    // 1. Socket / Network Connection
    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('networkrequestfailedexception') ||
        errorStr.contains('clientexception') ||
        errorStr.contains('connection') ||
        errorStr.contains('network error') ||
        errorStr.contains('handshake') ||
        errorStr.contains('xmlhttprequest')) {
      return 'No internet connection';
    }

    // 2. Timeout
    if (errorStr.contains('timeout') ||
        errorStr.contains('time out') ||
        errorStr.contains('timed out')) {
      return 'Request timed out';
    }

    // 3. Invalid credentials
    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid credentials') ||
        errorStr.contains('wrong email/password') ||
        errorStr.contains('invalid_credentials')) {
      return 'Incorrect email or password';
    }

    // 4. Email not confirmed
    if (errorStr.contains('email not confirmed') ||
        errorStr.contains('email_not_confirmed') ||
        errorStr.contains('email confirmation') ||
        errorStr.contains('confirm your email') ||
        errorStr.contains('email_not_confirmed')) {
      return 'Please verify your email';
    }

    // 5. User already registered
    if (errorStr.contains('user already registered') ||
        errorStr.contains('user_already_registered') ||
        errorStr.contains('already registered') ||
        errorStr.contains('email already in use') ||
        errorStr.contains('user already exists') ||
        errorStr.contains('email already exists')) {
      return 'Account already exists';
    }

    // 6. Weak password
    if (errorStr.contains('weak password') ||
        errorStr.contains('weak_password') ||
        errorStr.contains('password is too weak') ||
        errorStr.contains('password_too_weak')) {
      return 'Password is too weak';
    }

    // 7. User/email not found
    if (errorStr.contains('user not found') ||
        errorStr.contains('email does not exist') ||
        errorStr.contains('user_not_found') ||
        errorStr.contains('email_not_found')) {
      return 'No account found with this email';
    }

    // Default/Unknown
    return 'Something went wrong';
  }
}
