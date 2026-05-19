/// Input validators for forms and fields
class Validators {
  Validators._();

  /// Validates phone number (basic international format)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.length < 10 || cleaned.length > 15) {
      return 'Enter a valid phone number';
    }
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates OTP code
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'Enter 6-digit OTP';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must be numeric';
    }
    return null;
  }

  /// Validates username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 30) {
      return 'Username must be less than 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only letters, numbers, and underscores';
    }
    return null;
  }

  /// Validates display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  /// Validates bio text
  static String? validateBio(String? value) {
    if (value != null && value.length > 150) {
      return 'Bio must be less than 150 characters';
    }
    return null;
  }

  /// Validates message text
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (value.length > 4096) {
      return 'Message is too long';
    }
    return null;
  }

  /// Validates group name
  static String? validateGroupName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Group name is required';
    }
    if (value.length < 2) {
      return 'Group name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Group name must be less than 50 characters';
    }
    return null;
  }
}
