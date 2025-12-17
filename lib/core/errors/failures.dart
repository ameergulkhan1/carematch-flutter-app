import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
/// Failures represent expected errors that can occur during business logic execution.
/// They are used to communicate error states from the data layer to the presentation layer.
abstract class Failure extends Equatable {
  /// Human-readable error message
  final String message;

  /// Optional error code for categorization and tracking
  final String? code;

  /// Optional error details for debugging
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Represents failures that occur when communicating with remote servers or APIs
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
    super.details,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];

  /// Factory constructors for common server errors
  factory ServerFailure.notFound([String? message]) {
    return ServerFailure(
      message: message ?? 'Resource not found.',
      code: 'not-found',
      statusCode: 404,
    );
  }

  factory ServerFailure.unauthorized([String? message]) {
    return ServerFailure(
      message: message ?? 'Unauthorized access.',
      code: 'unauthorized',
      statusCode: 401,
    );
  }

  @override
  String toString() =>
      'ServerFailure(message: $message, code: $code, statusCode: $statusCode)';
}

/// Represents failures that occur when accessing local cache or storage
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'CacheFailure(message: $message, code: $code)';
}

/// Represents failures related to network connectivity
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    String? code,
    super.details,
  }) : super(
          code: code ?? 'network-error',
        );

  /// Factory constructor for common network error scenarios
  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      message: 'No internet connection. Please check your network settings.',
      code: 'no-connection',
    );
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      message: 'Connection timeout. Please try again.',
      code: 'timeout',
    );
  }

  factory NetworkFailure.slow() {
    return const NetworkFailure(
      message: 'Slow or unstable connection. Please check your network.',
      code: 'slow-connection',
    );
  }

  @override
  String toString() => 'NetworkFailure(message: $message, code: $code)';
}

/// Represents failures related to authentication and authorization
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    String? code,
    super.details,
  }) : super(
          code: code ?? 'auth-error',
        );

  /// Factory constructors for common authentication scenarios
  factory AuthenticationFailure.unauthenticated() {
    return const AuthenticationFailure(
      message: 'You are not signed in. Please sign in to continue.',
      code: 'unauthenticated',
    );
  }

  factory AuthenticationFailure.unauthorized() {
    return const AuthenticationFailure(
      message: 'You do not have permission to perform this action.',
      code: 'unauthorized',
    );
  }

  factory AuthenticationFailure.sessionExpired() {
    return const AuthenticationFailure(
      message: 'Your session has expired. Please sign in again.',
      code: 'session-expired',
    );
  }

  factory AuthenticationFailure.invalidCredentials() {
    return const AuthenticationFailure(
      message: 'Invalid email or password. Please try again.',
      code: 'invalid-credentials',
    );
  }

  factory AuthenticationFailure.accountDisabled() {
    return const AuthenticationFailure(
      message: 'Your account has been disabled. Please contact support.',
      code: 'account-disabled',
    );
  }

  factory AuthenticationFailure.emailNotVerified() {
    return const AuthenticationFailure(
      message: 'Please verify your email address to continue.',
      code: 'email-not-verified',
    );
  }

  @override
  String toString() =>
      'AuthenticationFailure(message: $message, code: $code)';
}

/// Represents failures that occur during input validation
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    String? code,
    this.fieldErrors,
    super.details,
  }) : super(
          code: code ?? 'validation-error',
        );

  /// Factory constructor for single field validation errors
  factory ValidationFailure.field(String field, String error) {
    return ValidationFailure(
      message: error,
      code: 'field-validation',
      fieldErrors: {field: error},
    );
  }

  /// Factory constructor for multiple field validation errors
  factory ValidationFailure.fields(Map<String, String> errors) {
    return ValidationFailure(
      message: 'Please fix the following errors',
      code: 'multiple-field-validation',
      fieldErrors: errors,
    );
  }

  factory ValidationFailure.required(String field) {
    return ValidationFailure(
      message: '$field is required',
      code: 'required-field',
      fieldErrors: {field: '$field is required'},
    );
  }

  factory ValidationFailure.invalidFormat(String field) {
    return ValidationFailure(
      message: 'Invalid $field format',
      code: 'invalid-format',
      fieldErrors: {field: 'Invalid $field format'},
    );
  }

  @override
  List<Object?> get props => [...super.props, fieldErrors];

  @override
  String toString() =>
      'ValidationFailure(message: $message, code: $code, fieldErrors: $fieldErrors)';
}

/// Represents failures related to business logic or domain rules
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure({
    required super.message,
    String? code,
    super.details,
  }) : super(
          code: code ?? 'business-logic-error',
        );

  @override
  String toString() =>
      'BusinessLogicFailure(message: $message, code: $code)';
}

/// Represents failures that occur during file operations
class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    String? code,
    super.details,
  }) : super(
          code: code ?? 'file-error',
        );

  factory FileFailure.notFound() {
    return const FileFailure(
      message: 'File not found',
      code: 'file-not-found',
    );
  }

  factory FileFailure.tooLarge(int maxSizeMB) {
    return FileFailure(
      message: 'File size exceeds the maximum allowed size of $maxSizeMB MB',
      code: 'file-too-large',
      details: {'maxSizeMB': maxSizeMB},
    );
  }

  factory FileFailure.unsupportedFormat(String format) {
    return FileFailure(
      message: 'Unsupported file format: $format',
      code: 'unsupported-format',
      details: {'format': format},
    );
  }

  @override
  String toString() => 'FileFailure(message: $message, code: $code)';
}

/// Represents failures related to payment processing
class PaymentFailure extends Failure {
  const PaymentFailure({
    required super.message,
    String? code,
    super.details,
  }) : super(
          code: code ?? 'payment-error',
        );

  factory PaymentFailure.insufficientFunds() {
    return const PaymentFailure(
      message: 'Insufficient funds. Please add money to your wallet.',
      code: 'insufficient-funds',
    );
  }

  factory PaymentFailure.cardDeclined() {
    return const PaymentFailure(
      message: 'Your card was declined. Please try another payment method.',
      code: 'card-declined',
    );
  }

  factory PaymentFailure.processingError() {
    return const PaymentFailure(
      message: 'Payment processing failed. Please try again.',
      code: 'processing-error',
    );
  }

  @override
  String toString() => 'PaymentFailure(message: $message, code: $code)';
}

/// Represents unexpected or unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    String? code,
    super.details,
  }) : super(
          code: code ?? 'unknown-error',
        );

  @override
  String toString() => 'UnknownFailure(message: $message, code: $code)';
}
