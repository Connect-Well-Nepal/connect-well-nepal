/// Validators - Form validation utilities for Connect Well Nepal
///
/// Provides validation for:
/// - Email addresses
/// - Passwords
/// - Phone numbers
/// - Names
/// - Medical license numbers
/// - General input validation
class Validators {
  // Private constructor
  Validators._();

  // ============== EMAIL VALIDATION ==============

  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Basic email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Check if email is valid (returns bool)
  static bool isValidEmail(String email) {
    return validateEmail(email) == null;
  }

  // ============== PASSWORD VALIDATION ==============

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validate strong password (with requirements)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ============== PHONE VALIDATION ==============

  /// Validate phone number (Nepal format)
  static String? validatePhone(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Nepal phone number patterns:
    // - Mobile: 98XXXXXXXX, 97XXXXXXXX (10 digits)
    // - With country code: +977XXXXXXXXXX
    final nepalMobileRegex = RegExp(r'^(\+977)?9[78]\d{8}$');

    if (!nepalMobileRegex.hasMatch(cleaned)) {
      return 'Please enter a valid Nepal phone number';
    }

    return null;
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.startsWith('+977')) {
      // +977 98XXXXXXXX -> +977 98XX XXX XXX
      final number = cleaned.substring(4);
      return '+977 ${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7)}';
    } else if (cleaned.length == 10) {
      // 98XXXXXXXX -> 98XX XXX XXX
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }

    return phone;
  }

  // ============== NAME VALIDATION ==============

  /// Validate name
  static String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < minLength) {
      return 'Name must be at least $minLength characters';
    }

    // Allow letters, spaces, and common name characters
    if (!RegExp(r"^[a-zA-Z\s\-'.]+$").hasMatch(value)) {
      return 'Name contains invalid characters';
    }

    return null;
  }

  /// Validate full name (first and last)
  static String? validateFullName(String? value) {
    final nameError = validateName(value);
    if (nameError != null) return nameError;

    final parts = value!.trim().split(' ');
    if (parts.length < 2) {
      return 'Please enter your full name (first and last)';
    }

    return null;
  }

  // ============== MEDICAL LICENSE VALIDATION ==============

  /// Validate medical license number
  static String? validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }

    // Nepal Medical Council format: NMC-XXXXX or NMC/XXXXX
    final nmcRegex = RegExp(r'^(NMC[-/]?)?\d{4,6}$', caseSensitive: false);

    if (!nmcRegex.hasMatch(value.trim())) {
      return 'Please enter a valid license number (e.g., NMC-12345)';
    }

    return null;
  }

  // ============== GENERAL VALIDATION ==============

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value, String fieldName, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, String fieldName, {bool required = true}) {
    final numericError = validateNumeric(value, fieldName, required: required);
    if (numericError != null) return numericError;

    if (value != null && value.isNotEmpty) {
      final number = int.tryParse(value);
      if (number != null && number <= 0) {
        return '$fieldName must be a positive number';
      }
    }

    return null;
  }

  /// Validate age
  static String? validateAge(String? value, {int minAge = 0, int maxAge = 120}) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }

    if (age < minAge || age > maxAge) {
      return 'Age must be between $minAge and $maxAge';
    }

    return null;
  }

  /// Validate years of experience
  static String? validateExperience(String? value) {
    if (value == null || value.isEmpty) {
      return 'Years of experience is required';
    }

    final years = int.tryParse(value);
    if (years == null) {
      return 'Please enter a valid number';
    }

    if (years < 0) {
      return 'Experience cannot be negative';
    }

    if (years > 60) {
      return 'Please enter a realistic experience value';
    }

    return null;
  }

  // ============== DATE VALIDATION ==============

  /// Validate date of birth
  static String? validateDateOfBirth(DateTime? date) {
    if (date == null) {
      return 'Date of birth is required';
    }

    final now = DateTime.now();
    final age = now.year - date.year;

    if (date.isAfter(now)) {
      return 'Date cannot be in the future';
    }

    if (age > 120) {
      return 'Please enter a valid date of birth';
    }

    return null;
  }

  /// Validate appointment date (must be in future)
  static String? validateFutureDate(DateTime? date, String fieldName) {
    if (date == null) {
      return '$fieldName is required';
    }

    if (date.isBefore(DateTime.now())) {
      return '$fieldName must be in the future';
    }

    return null;
  }

  // ============== URL VALIDATION ==============

  /// Validate URL
  static String? validateUrl(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'URL is required' : null;
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }
}
