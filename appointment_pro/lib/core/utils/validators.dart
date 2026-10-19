class Validators {
  Validators._();

  /// Full Name: Required, minimum 2 characters, letters and spaces only (optionally allow hyphens).
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s\-]+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Full name can only contain letters, spaces, and hyphens';
    }
    return null;
  }

  /// Email: Required, valid email format, trim whitespace.
  /// Also ensures email is unique from password.
  static String? validateEmail(String? value, {String? password}) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    if (password != null &&
        password.isNotEmpty &&
        trimmed.toLowerCase() == password.trim().toLowerCase()) {
      return 'Email and password must be unique (cannot be the same)';
    }
    return null;
  }

  /// Phone: Required, valid 10-digit Indian mobile number, digits only.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = value.trim();
    final digitsOnly = RegExp(r'^\d+$');
    if (!digitsOnly.hasMatch(trimmed)) {
      return 'Phone number must contain digits only';
    }
    if (trimmed.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  /// Password: Required, minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 digit, and 1 special character.
  /// Also ensures password is unique from email.
  static String? validatePassword(String? value, {String? email}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (email != null &&
        email.trim().isNotEmpty &&
        value.trim().toLowerCase() == email.trim().toLowerCase()) {
      return 'Email and password must be unique (cannot be the same)';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least 1 uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least 1 lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least 1 digit';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_+\-=\[\]\\/`~;\x27]').hasMatch(value)) {
      return 'Password must contain at least 1 special character';
    }
    return null;
  }

  /// Confirm Password: Required, must match the password exactly.
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
