import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Application-wide logger with customized output formatting.
/// Uses different log levels and provides pretty printing in debug mode.
class AppLogger {
  static final Logger _logger = Logger(
    printer: kDebugMode
        ? PrettyPrinter(
            methodCount: 2, // Number of method calls to display
            errorMethodCount: 8, // Number of method calls for errors
            lineLength: 120, // Width of output
            colors: true, // Colorful output
            printEmojis: true, // Print emojis for log levels
            printTime: true, // Print timestamp
          )
        : SimplePrinter(),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Debug log - for detailed debugging information
  /// Only visible in debug builds
  static void d(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Info log - for general information
  static void i(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning log - for warning messages
  static void w(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error log - for error messages
  static void e(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal log - for critical errors
  static void f(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log network request
  static void network({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    int? statusCode,
    dynamic response,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━ HTTP REQUEST ━━━━━━');
    buffer.writeln('Method: $method');
    buffer.writeln('URL: $url');
    if (headers != null) {
      buffer.writeln('Headers: $headers');
    }
    if (body != null) {
      buffer.writeln('Body: $body');
    }
    if (statusCode != null) {
      buffer.writeln('Status: $statusCode');
    }
    if (response != null) {
      buffer.writeln('Response: $response');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _logger.d(buffer.toString());
  }

  /// Log Firebase operation
  static void firebase({
    required String operation,
    required String collection,
    String? documentId,
    Map<String, dynamic>? data,
    dynamic result,
    dynamic error,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('🔥 FIREBASE: $operation');
    buffer.writeln('Collection: $collection');
    if (documentId != null) {
      buffer.writeln('Document ID: $documentId');
    }
    if (data != null) {
      buffer.writeln('Data: $data');
    }
    if (result != null) {
      buffer.writeln('Result: $result');
    }
    if (error != null) {
      buffer.writeln('Error: $error');
    }

    if (error != null) {
      _logger.e(buffer.toString());
    } else {
      _logger.d(buffer.toString());
    }
  }

  /// Log navigation
  static void navigation({
    required String from,
    required String to,
    Map<String, dynamic>? arguments,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('🧭 NAVIGATION');
    buffer.writeln('From: $from');
    buffer.writeln('To: $to');
    if (arguments != null) {
      buffer.writeln('Arguments: $arguments');
    }

    _logger.d(buffer.toString());
  }

  /// Log state change
  static void state({
    required String widget,
    required String event,
    dynamic oldValue,
    dynamic newValue,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('🔄 STATE CHANGE: $widget');
    buffer.writeln('Event: $event');
    if (oldValue != null) {
      buffer.writeln('Old: $oldValue');
    }
    if (newValue != null) {
      buffer.writeln('New: $newValue');
    }

    _logger.d(buffer.toString());
  }

  /// Log user action
  static void userAction({
    required String action,
    String? userId,
    Map<String, dynamic>? details,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('👤 USER ACTION: $action');
    if (userId != null) {
      buffer.writeln('User ID: $userId');
    }
    if (details != null) {
      buffer.writeln('Details: $details');
    }

    _logger.i(buffer.toString());
  }

  /// Log performance metric
  static void performance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? details,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('⚡ PERFORMANCE: $operation');
    buffer.writeln('Duration: ${duration.inMilliseconds}ms');
    if (details != null) {
      buffer.writeln('Details: $details');
    }

    if (duration.inMilliseconds > 1000) {
      _logger.w(buffer.toString());
    } else {
      _logger.d(buffer.toString());
    }
  }
}

/// Extension to add logging to futures
extension FutureLogger<T> on Future<T> {
  /// Log the execution time of a future
  Future<T> withLogging(String operation) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await this;
      stopwatch.stop();
      AppLogger.performance(
        operation: operation,
        duration: stopwatch.elapsed,
      );
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      AppLogger.e(
        'Failed: $operation',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
