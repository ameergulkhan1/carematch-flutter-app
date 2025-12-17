import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Centralized error handler for the entire application.
/// Converts exceptions to failures and provides user-friendly error messages.
class ErrorHandler {
  /// Convert any exception to a Failure
  static Failure handleException(dynamic error, [StackTrace? stackTrace]) {
    // Log error for debugging (in production, send to crash reporting service)
    _logError(error, stackTrace);

    // Handle known exception types
    if (error is ServerException) {
      return _handleServerException(error);
    } else if (error is CacheException) {
      return _handleCacheException(error);
    } else if (error is NetworkException) {
      return _handleNetworkException(error);
    } else if (error is AuthenticationException) {
      return _handleAuthenticationException(error);
    } else if (error is ValidationException) {
      return _handleValidationException(error);
    } else if (error is FileException) {
      return _handleFileException(error);
    } else if (error is PaymentException) {
      return _handlePaymentException(error);
    } else if (error is PermissionException) {
      return _handlePermissionException(error);
    }

    // Handle Firebase exceptions
    else if (error is FirebaseException) {
      return handleFirebaseError(error);
    } else if (error is firebase_auth.FirebaseAuthException) {
      return handleFirebaseAuthError(error);
    }

    // Handle standard Dart exceptions
    else if (error is SocketException) {
      return NetworkFailure.noConnection();
    } else if (error is TimeoutException) {
      return NetworkFailure.timeout();
    } else if (error is FormatException) {
      return const ValidationFailure(
        message: 'Invalid data format',
        code: 'format-exception',
      );
    }

    // Unknown error
    return UnknownFailure(
      message: error?.toString() ?? 'An unexpected error occurred',
      details: error,
    );
  }

  /// Handle Firebase general exceptions
  static Failure handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      // Firestore errors
      case 'permission-denied':
        return AuthenticationFailure(
          message: 'You do not have permission to perform this action',
          code: error.code,
          details: error.message,
        );

      case 'not-found':
        return ServerFailure(
          message: 'The requested resource was not found',
          code: error.code,
          statusCode: 404,
          details: error.message,
        );

      case 'already-exists':
        return ServerFailure(
          message: 'A resource with this identifier already exists',
          code: error.code,
          statusCode: 409,
          details: error.message,
        );

      case 'resource-exhausted':
        return ServerFailure(
          message: 'Resource quota exceeded. Please try again later',
          code: error.code,
          statusCode: 429,
          details: error.message,
        );

      case 'failed-precondition':
        return ServerFailure(
          message: 'Operation cannot be completed in the current state',
          code: error.code,
          statusCode: 400,
          details: error.message,
        );

      case 'aborted':
        return ServerFailure(
          message: 'Operation was aborted. Please try again',
          code: error.code,
          details: error.message,
        );

      case 'out-of-range':
        return ValidationFailure(
          message: 'Value is out of valid range',
          code: error.code,
          details: error.message,
        );

      case 'unimplemented':
        return ServerFailure(
          message: 'This feature is not yet implemented',
          code: error.code,
          statusCode: 501,
          details: error.message,
        );

      case 'internal':
        return ServerFailure(
          message: 'Internal server error. Please try again later',
          code: error.code,
          statusCode: 500,
          details: error.message,
        );

      case 'unavailable':
        return ServerFailure(
          message: 'Service is temporarily unavailable',
          code: error.code,
          statusCode: 503,
          details: error.message,
        );

      case 'unauthenticated':
        return AuthenticationFailure.unauthenticated();

      case 'deadline-exceeded':
        return NetworkFailure.timeout();

      case 'cancelled':
        return const ServerFailure(
          message: 'Operation was cancelled',
          code: 'cancelled',
        );

      // Firebase Storage errors
      case 'storage/unauthorized':
        return AuthenticationFailure(
          message: 'You do not have permission to access this file',
          code: error.code,
        );

      case 'storage/retry-limit-exceeded':
        return const ServerFailure(
          message: 'Upload failed after multiple retries',
          code: 'retry-limit-exceeded',
        );

      case 'storage/invalid-checksum':
        return const FileFailure(
          message: 'File upload was corrupted. Please try again',
          code: 'invalid-checksum',
        );

      case 'storage/quota-exceeded':
        return const ServerFailure(
          message: 'Storage quota exceeded',
          code: 'quota-exceeded',
        );

      case 'storage/object-not-found':
        return FileFailure.notFound();

      default:
        return ServerFailure(
          message: error.message ?? 'A Firebase error occurred',
          code: error.code,
          details: error.message,
        );
    }
  }

  /// Handle Firebase Auth specific exceptions
  static Failure handleFirebaseAuthError(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return const AuthenticationFailure(
          message: 'The email address is invalid',
          code: 'invalid-email',
        );

      case 'user-disabled':
        return AuthenticationFailure.accountDisabled();

      case 'user-not-found':
        return const AuthenticationFailure(
          message: 'No account found with this email',
          code: 'user-not-found',
        );

      case 'wrong-password':
        return AuthenticationFailure.invalidCredentials();

      case 'invalid-credential':
        return AuthenticationFailure.invalidCredentials();

      case 'email-already-in-use':
        return const AuthenticationFailure(
          message: 'An account already exists with this email',
          code: 'email-already-in-use',
        );

      case 'operation-not-allowed':
        return const AuthenticationFailure(
          message: 'This operation is not allowed',
          code: 'operation-not-allowed',
        );

      case 'weak-password':
        return const AuthenticationFailure(
          message: 'Password is too weak. Please use a stronger password',
          code: 'weak-password',
        );

      case 'requires-recent-login':
        return const AuthenticationFailure(
          message: 'Please sign in again to continue',
          code: 'requires-recent-login',
        );

      case 'account-exists-with-different-credential':
        return const AuthenticationFailure(
          message: 'An account already exists with a different sign-in method',
          code: 'account-exists-with-different-credential',
        );

      case 'invalid-verification-code':
        return const AuthenticationFailure(
          message: 'Invalid verification code',
          code: 'invalid-verification-code',
        );

      case 'invalid-verification-id':
        return const AuthenticationFailure(
          message: 'Invalid verification ID',
          code: 'invalid-verification-id',
        );

      case 'too-many-requests':
        return const AuthenticationFailure(
          message: 'Too many attempts. Please try again later',
          code: 'too-many-requests',
        );

      case 'network-request-failed':
        return NetworkFailure.noConnection();

      case 'session-expired':
        return AuthenticationFailure.sessionExpired();

      case 'popup-closed-by-user':
        return const AuthenticationFailure(
          message: 'Sign-in cancelled',
          code: 'popup-closed-by-user',
        );

      default:
        return AuthenticationFailure(
          message: error.message ?? 'Authentication failed',
          code: error.code,
          details: error.message,
        );
    }
  }

  /// Get user-friendly error message from a Failure
  static String getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is CacheFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is AuthenticationFailure) {
      return failure.message;
    } else if (failure is FileFailure) {
      return failure.message;
    } else if (failure is PaymentFailure) {
      return failure.message;
    } else if (failure is BusinessLogicFailure) {
      return failure.message;
    } else if (failure is UnknownFailure) {
      return failure.message;
    }
    return 'An error occurred. Please try again.';
  }

  /// Check if error is due to network issues
  static bool isNetworkError(Failure failure) {
    return failure is NetworkFailure;
  }

  /// Check if error is due to authentication issues
  static bool isAuthError(Failure failure) {
    return failure is AuthenticationFailure;
  }

  /// Check if error is recoverable (can retry)
  static bool isRecoverable(Failure failure) {
    return failure is NetworkFailure ||
        failure is ServerFailure && 
            (failure.statusCode == 408 || // Request Timeout
             failure.statusCode == 429 || // Too Many Requests
             failure.statusCode == 503 || // Service Unavailable
             failure.statusCode == 504);  // Gateway Timeout
  }

  // Private helper methods

  static Failure _handleServerException(ServerException exception) {
    return ServerFailure(
      message: exception.message,
      code: exception.code,
      statusCode: exception.statusCode,
      details: exception.details,
    );
  }

  static Failure _handleCacheException(CacheException exception) {
    return CacheFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  static Failure _handleNetworkException(NetworkException exception) {
    return NetworkFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  static Failure _handleAuthenticationException(
      AuthenticationException exception) {
    return AuthenticationFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  static Failure _handleValidationException(ValidationException exception) {
    return ValidationFailure(
      message: exception.message,
      code: exception.code,
      fieldErrors: exception.fieldErrors,
      details: exception.details,
    );
  }

  static Failure _handleFileException(FileException exception) {
    return FileFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  static Failure _handlePaymentException(PaymentException exception) {
    return PaymentFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  static Failure _handlePermissionException(PermissionException exception) {
    return ServerFailure(
      message: exception.message,
      code: exception.code,
      details: exception.details,
    );
  }

  static void _logError(dynamic error, StackTrace? stackTrace) {
    // In development, print to console
    print('🔴 ERROR: $error');
    if (stackTrace != null) {
      print('📍 STACK TRACE:\n$stackTrace');
    }

    // In production, send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // Example:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

/// Extension to wrap async operations with error handling
extension FutureErrorHandling<T> on Future<T> {
  /// Wrap the future with error handling
  Future<T> handleErrors() async {
    try {
      return await this;
    } catch (error, stackTrace) {
      final failure = ErrorHandler.handleException(error, stackTrace);
      throw failure;
    }
  }
}
