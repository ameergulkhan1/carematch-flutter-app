/// Base exception class for all custom exceptions in the application.
/// Exceptions represent unexpected errors during data operations.
/// They should be caught and converted to Failures in the repository layer.
abstract class AppException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional error code
  final String? code;

  /// Optional additional details
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Exception thrown when a server/API request fails
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    this.statusCode,
    super.details,
  });

  /// Factory constructors for common HTTP status codes
  factory ServerException.badRequest([String? message]) {
    return ServerException(
      message: message ?? 'Bad request. Please check your input.',
      code: 'bad-request',
      statusCode: 400,
    );
  }

  factory ServerException.unauthorized([String? message]) {
    return ServerException(
      message: message ?? 'Unauthorized. Please sign in.',
      code: 'unauthorized',
      statusCode: 401,
    );
  }

  factory ServerException.forbidden([String? message]) {
    return ServerException(
      message: message ?? 'Access forbidden.',
      code: 'forbidden',
      statusCode: 403,
    );
  }

  factory ServerException.notFound([String? message]) {
    return ServerException(
      message: message ?? 'Resource not found.',
      code: 'not-found',
      statusCode: 404,
    );
  }

  factory ServerException.conflict([String? message]) {
    return ServerException(
      message: message ?? 'Resource conflict.',
      code: 'conflict',
      statusCode: 409,
    );
  }

  factory ServerException.internalServerError([String? message]) {
    return ServerException(
      message: message ?? 'Internal server error. Please try again later.',
      code: 'internal-server-error',
      statusCode: 500,
    );
  }

  factory ServerException.serviceUnavailable([String? message]) {
    return ServerException(
      message: message ?? 'Service temporarily unavailable.',
      code: 'service-unavailable',
      statusCode: 503,
    );
  }

  @override
  String toString() =>
      'ServerException(message: $message, code: $code, statusCode: $statusCode)';
}

/// Exception thrown when local cache/storage operations fail
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.details,
  });

  factory CacheException.readError([String? message]) {
    return CacheException(
      message: message ?? 'Failed to read from cache.',
      code: 'cache-read-error',
    );
  }

  factory CacheException.writeError([String? message]) {
    return CacheException(
      message: message ?? 'Failed to write to cache.',
      code: 'cache-write-error',
    );
  }

  factory CacheException.deleteError([String? message]) {
    return CacheException(
      message: message ?? 'Failed to delete from cache.',
      code: 'cache-delete-error',
    );
  }

  factory CacheException.notFound([String? message]) {
    return CacheException(
      message: message ?? 'Data not found in cache.',
      code: 'cache-not-found',
    );
  }

  factory CacheException.corrupted([String? message]) {
    return CacheException(
      message: message ?? 'Cached data is corrupted.',
      code: 'cache-corrupted',
    );
  }

  @override
  String toString() => 'CacheException(message: $message, code: $code)';
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.details,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      message: 'No internet connection.',
      code: 'no-connection',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      message: 'Connection timeout.',
      code: 'timeout',
    );
  }

  factory NetworkException.requestCancelled() {
    return const NetworkException(
      message: 'Request was cancelled.',
      code: 'request-cancelled',
    );
  }

  factory NetworkException.hostUnreachable() {
    return const NetworkException(
      message: 'Host unreachable.',
      code: 'host-unreachable',
    );
  }

  @override
  String toString() => 'NetworkException(message: $message, code: $code)';
}

/// Exception thrown for authentication-related errors
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code,
    super.details,
  });

  factory AuthenticationException.invalidCredentials() {
    return const AuthenticationException(
      message: 'Invalid credentials.',
      code: 'invalid-credentials',
    );
  }

  factory AuthenticationException.userNotFound() {
    return const AuthenticationException(
      message: 'User not found.',
      code: 'user-not-found',
    );
  }

  factory AuthenticationException.emailAlreadyInUse() {
    return const AuthenticationException(
      message: 'Email already in use.',
      code: 'email-already-in-use',
    );
  }

  factory AuthenticationException.weakPassword() {
    return const AuthenticationException(
      message: 'Password is too weak.',
      code: 'weak-password',
    );
  }

  factory AuthenticationException.accountDisabled() {
    return const AuthenticationException(
      message: 'Account has been disabled.',
      code: 'account-disabled',
    );
  }

  factory AuthenticationException.tooManyRequests() {
    return const AuthenticationException(
      message: 'Too many requests. Please try again later.',
      code: 'too-many-requests',
    );
  }

  factory AuthenticationException.unauthenticated() {
    return const AuthenticationException(
      message: 'User is not authenticated.',
      code: 'unauthenticated',
    );
  }

  @override
  String toString() =>
      'AuthenticationException(message: $message, code: $code)';
}

/// Exception thrown for validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code,
    this.fieldErrors,
    super.details,
  });

  factory ValidationException.field(String field, String error) {
    return ValidationException(
      message: error,
      code: 'field-validation',
      fieldErrors: {field: error},
    );
  }

  factory ValidationException.fields(Map<String, String> errors) {
    return ValidationException(
      message: 'Validation failed',
      code: 'multiple-field-validation',
      fieldErrors: errors,
    );
  }

  @override
  String toString() =>
      'ValidationException(message: $message, code: $code, fieldErrors: $fieldErrors)';
}

/// Exception thrown for file-related operations
class FileException extends AppException {
  const FileException({
    required super.message,
    super.code,
    super.details,
  });

  factory FileException.notFound() {
    return const FileException(
      message: 'File not found.',
      code: 'file-not-found',
    );
  }

  factory FileException.tooLarge() {
    return const FileException(
      message: 'File is too large.',
      code: 'file-too-large',
    );
  }

  factory FileException.unsupportedFormat() {
    return const FileException(
      message: 'Unsupported file format.',
      code: 'unsupported-format',
    );
  }

  factory FileException.uploadFailed() {
    return const FileException(
      message: 'File upload failed.',
      code: 'upload-failed',
    );
  }

  @override
  String toString() => 'FileException(message: $message, code: $code)';
}

/// Exception thrown for permission-related errors
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.details,
  });

  factory PermissionException.denied(String permission) {
    return PermissionException(
      message: '$permission permission denied.',
      code: 'permission-denied',
      details: {'permission': permission},
    );
  }

  factory PermissionException.permanentlyDenied(String permission) {
    return PermissionException(
      message: '$permission permission permanently denied.',
      code: 'permission-permanently-denied',
      details: {'permission': permission},
    );
  }

  @override
  String toString() => 'PermissionException(message: $message, code: $code)';
}

/// Exception thrown for payment-related errors
class PaymentException extends AppException {
  const PaymentException({
    required super.message,
    super.code,
    super.details,
  });

  factory PaymentException.insufficientFunds() {
    return const PaymentException(
      message: 'Insufficient funds.',
      code: 'insufficient-funds',
    );
  }

  factory PaymentException.cardDeclined() {
    return const PaymentException(
      message: 'Card declined.',
      code: 'card-declined',
    );
  }

  factory PaymentException.processingError() {
    return const PaymentException(
      message: 'Payment processing error.',
      code: 'processing-error',
    );
  }

  @override
  String toString() => 'PaymentException(message: $message, code: $code)';
}

/// Exception thrown for parsing/serialization errors
class ParsingException extends AppException {
  const ParsingException({
    required super.message,
    super.code,
    super.details,
  });

  factory ParsingException.jsonParsing() {
    return const ParsingException(
      message: 'Failed to parse JSON data.',
      code: 'json-parsing-error',
    );
  }

  factory ParsingException.dataFormat() {
    return const ParsingException(
      message: 'Invalid data format.',
      code: 'invalid-data-format',
    );
  }

  @override
  String toString() => 'ParsingException(message: $message, code: $code)';
}
