import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ==================== STRING EXTENSIONS ====================

/// Extension methods for String manipulation and validation
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalize first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize())
        .join(' ');
  }

  /// Convert to title case
  String toTitleCase() {
    return capitalizeWords();
  }

  /// Remove all whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// Check if string is a valid phone number
  bool get isValidPhone {
    final digitsOnly = replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  /// Check if string is a valid URL
  bool get isValidUrl {
    return RegExp(
            r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b')
        .hasMatch(this);
  }

  /// Check if string contains only numbers
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Check if string contains only letters
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Check if string contains only letters and numbers
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  /// Convert string to int safely
  int? toIntOrNull() {
    return int.tryParse(this);
  }

  /// Convert string to double safely
  double? toDoubleOrNull() {
    return double.tryParse(this);
  }

  /// Parse string to DateTime
  DateTime? toDateTimeOrNull() {
    return DateTime.tryParse(this);
  }

  /// Get initials from name (e.g., "John Doe" -> "JD")
  String getInitials({int maxLetters = 2}) {
    final words = trim().split(' ');
    if (words.isEmpty) return '';

    final initials = words
        .where((word) => word.isNotEmpty)
        .take(maxLetters)
        .map((word) => word[0].toUpperCase())
        .join();

    return initials;
  }

  /// Mask email (e.g., "john@example.com" -> "j***@example.com")
  String maskEmail() {
    if (!isValidEmail) return this;

    final parts = split('@');
    if (parts.length != 2) return this;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 1) return this;

    return '${username[0]}${'*' * (username.length - 1)}@$domain';
  }

  /// Mask phone number (e.g., "+1234567890" -> "+******7890")
  String maskPhone() {
    final digitsOnly = replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 4) return this;

    final visibleDigits = digitsOnly.substring(digitsOnly.length - 4);
    final maskedPart = '*' * (digitsOnly.length - 4);

    return '+$maskedPart$visibleDigits';
  }

  /// Convert to currency format
  String toCurrency({String symbol = '\$', int decimals = 2}) {
    final number = toDoubleOrNull();
    if (number == null) return this;

    return '$symbol${number.toStringAsFixed(decimals)}';
  }
}

// ==================== DATETIME EXTENSIONS ====================

/// Extension methods for DateTime manipulation and formatting
extension DateTimeExtension on DateTime {
  /// Format to readable string (e.g., "Jan 15, 2024")
  String toFormattedString() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format to date only (e.g., "01/15/2024")
  String toDateString() {
    return DateFormat('MM/dd/yyyy').format(this);
  }

  /// Format to time only (e.g., "02:30 PM")
  String toTimeString() {
    return DateFormat('hh:mm a').format(this);
  }

  /// Format to full date time (e.g., "Jan 15, 2024 at 02:30 PM")
  String toFullString() {
    return DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(this);
  }

  /// Get relative time (e.g., "2 hours ago", "3 days ago")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Check if date is same day as another
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if date is today
  bool isToday() {
    return isSameDay(DateTime.now());
  }

  /// Check if date is yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Check if date is tomorrow
  bool isTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(tomorrow);
  }

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Get start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Get age from birthdate
  int get age {
    final today = DateTime.now();
    int age = today.year - year;
    if (today.month < month || (today.month == month && today.day < day)) {
      age--;
    }
    return age;
  }

  /// Add working days (skip weekends)
  DateTime addWorkingDays(int days) {
    DateTime result = this;
    int addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }

    return result;
  }

  /// Check if it's a weekend
  bool get isWeekend {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Check if it's a weekday
  bool get isWeekday => !isWeekend;
}

// ==================== NUMBER EXTENSIONS ====================

/// Extension methods for num (int and double)
extension NumExtension on num {
  /// Format as currency
  String toCurrency({String symbol = '\$', int decimals = 2}) {
    return '$symbol${toStringAsFixed(decimals)}';
  }

  /// Format with thousand separators
  String toFormattedString() {
    return NumberFormat('#,##0.##').format(this);
  }

  /// Convert to percentage string
  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Check if number is between two values
  bool isBetween(num min, num max) {
    return this >= min && this <= max;
  }

  /// Clamp value between min and max
  num clampValue(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

// ==================== LIST EXTENSIONS ====================

/// Extension methods for List
extension ListExtension<T> on List<T> {
  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Group list items by a key
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final item in this) {
      final key = keyFunction(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Get distinct items
  List<T> distinct() {
    return toSet().toList();
  }

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}

// ==================== CONTEXT EXTENSIONS ====================

/// Extension methods for BuildContext
extension ContextExtension on BuildContext {
  /// Show snackbar
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, isError: true);
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message, isError: false);
  }

  /// Navigate to route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(this, routeName, arguments: arguments);
  }

  /// Navigate and replace
  Future<T?> pushReplacementNamed<T, TO>(String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, TO>(
      this,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and clear stack
  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      this,
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Pop current route
  void pop<T>([T? result]) {
    Navigator.pop<T>(this, result);
  }

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

// ==================== DURATION EXTENSIONS ====================

/// Extension methods for Duration
extension DurationExtension on Duration {
  /// Format duration as human-readable string
  String toHumanReadable() {
    if (inDays > 0) {
      return '$inDays ${inDays == 1 ? 'day' : 'days'}';
    } else if (inHours > 0) {
      return '$inHours ${inHours == 1 ? 'hour' : 'hours'}';
    } else if (inMinutes > 0) {
      return '$inMinutes ${inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return '$inSeconds ${inSeconds == 1 ? 'second' : 'seconds'}';
    }
  }

  /// Format as HH:MM:SS
  String toTimeFormat() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
