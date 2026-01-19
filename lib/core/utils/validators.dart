class Validator {
  // -------------------------
  // Email Validator
  // -------------------------
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return "Email cannot be empty";
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return "Enter a valid email";
    }

    return null; // valid
  }

  // -------------------------
  // Password Validator
  // -------------------------
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return "Password cannot be empty";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null; // valid
  }

  // -------------------------
  // Name Validator
  // -------------------------
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return "Name cannot be empty";
    }

    if (name.length < 2) {
      return "Name too short";
    }

    return null;
  }

  // -------------------------
  // Optional: Phone Number Validator
  // -------------------------
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return "Phone number cannot be empty";
    }

    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(phone)) {
      return "Enter a valid phone number";
    }

    return null;
  }
}
