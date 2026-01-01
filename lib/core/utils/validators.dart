/// Comprehensive validation utilities for form inputs and data validation
class Validators {
  // ==================== EMAIL VALIDATION ====================

  /// Validate email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Check if email is valid (returns bool)
  static bool isValidEmail(String? value) {
    return email(value) == null;
  }

  // ==================== PASSWORD VALIDATION ====================

  /// Validate password with strength requirements
  static String? password(String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumber = true,
    bool requireSpecialChar = true,
  }) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (requireNumber && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (requireSpecialChar && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Get password strength (0-4: weak to very strong)
  static int getPasswordStrength(String? password) {
    if (password == null || password.isEmpty) return 0;

    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[A-Z]')) && 
        password.contains(RegExp(r'[a-z]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength > 4 ? 4 : strength;
  }

  // ==================== PHONE NUMBER VALIDATION ====================

  /// Validate phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate phone with specific format
  static String? phoneNumberWithFormat(String? value, {required String format}) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(format).hasMatch(value)) {
      return 'Please enter phone number in correct format';
    }

    return null;
  }

  // ==================== NAME VALIDATION ====================

  /// Validate name (first/last name)
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return '$fieldName must not exceed 50 characters';
    }

    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // ==================== GENERIC VALIDATION ====================

  /// Validate required field
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < min) {
      return '$fieldName must be at least $min characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'Field',
  }) {
    if (value != null && value.length > max) {
      return '$fieldName must not exceed $max characters';
    }
    return null;
  }

  /// Validate length range
  static String? lengthRange(
    String? value,
    int min,
    int max, {
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < min || value.length > max) {
      return '$fieldName must be between $min and $max characters';
    }

    return null;
  }

  // ==================== NUMBER VALIDATION ====================

  /// Validate number
  static String? number(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }

    return null;
  }

  /// Validate integer
  static String? integer(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (int.tryParse(value) == null) {
      return '$fieldName must be a valid whole number';
    }

    return null;
  }

  /// Validate number in range
  static String? numberRange(
    String? value,
    double min,
    double max, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  // ==================== DATE VALIDATION ====================

  /// Validate date is not in the past
  static String? futureDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isBefore(DateTime.now())) {
      return '$fieldName must be in the future';
    }

    return null;
  }

  /// Validate date is not in the future
  static String? pastDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isAfter(DateTime.now())) {
      return '$fieldName must be in the past';
    }

    return null;
  }

  /// Validate age
  static String? age(DateTime? birthDate, {int minAge = 18, int maxAge = 100}) {
    if (birthDate == null) {
      return 'Date of birth is required';
    }

    final today = DateTime.now();
    final age = today.year - birthDate.year - 
        ((today.month > birthDate.month || 
          (today.month == birthDate.month && today.day >= birthDate.day))
            ? 0
            : 1);

    if (age < minAge) {
      return 'You must be at least $minAge years old';
    }

    if (age > maxAge) {
      return 'Please enter a valid date of birth';
    }

    return null;
  }

  // ==================== URL VALIDATION ====================

  /// Validate URL
  static String? url(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // ==================== CARD VALIDATION ====================

  /// Validate credit card number (basic Luhn algorithm)
  static String? creditCard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }

    final cardNumber = value.replaceAll(RegExp(r'\s'), '');

    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Please enter a valid card number';
    }

    if (!_luhnCheck(cardNumber)) {
      return 'Please enter a valid card number';
    }

    return null;
  }

  /// Validate CVV
  static String? cvv(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }

    if (value.length < 3 || value.length > 4) {
      return 'CVV must be 3 or 4 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'CVV must contain only digits';
    }

    return null;
  }

  /// Validate expiry date (MM/YY format)
  static String? expiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Expiry date must be in MM/YY format';
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return 'Invalid month';
    }

    if (year == null) {
      return 'Invalid year';
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;

    if (year < currentYear || (year == currentYear && month < now.month)) {
      return 'Card has expired';
    }

    return null;
  }

  // ==================== BUSINESS LOGIC VALIDATION ====================

  /// Validate hourly rate
  static String? hourlyRate(String? value, {double min = 10.0, double max = 200.0}) {
    if (value == null || value.trim().isEmpty) {
      return 'Hourly rate is required';
    }

    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Please enter a valid rate';
    }

    if (rate < min || rate > max) {
      return 'Rate must be between \$$min and \$$max';
    }

    return null;
  }

  /// Validate address
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 5) {
      return 'Please enter a complete address';
    }

    return null;
  }

  /// Validate zip/postal code
  static String? zipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ZIP code is required';
    }

    // US ZIP code format (5 digits or 5+4 digits)
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value.trim())) {
      return 'Please enter a valid ZIP code';
    }

    return null;
  }

  // ==================== HELPER METHODS ====================

  /// Luhn algorithm for credit card validation
  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Combine multiple validators
  static String? combine(
    List<String? Function()> validators,
  ) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }
}
