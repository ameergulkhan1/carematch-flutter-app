import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/auth_credentials.dart';

/// Abstract repository interface for authentication
/// This defines the contract that the data layer must implement
/// All methods return Either<Failure, Success> for error handling
abstract class AuthRepository {
  /// Sign in with email and password
  /// Returns Either<Failure, UserEntity> on success
  Future<Either<Failure, UserEntity>> signIn(SignInCredentials credentials);

  /// Register a new client user
  /// Returns Either<Failure, ClientUserEntity> on success
  Future<Either<Failure, ClientUserEntity>> registerClient(
    ClientSignUpCredentials credentials,
  );

  /// Register a new caregiver user
  /// Returns Either<Failure, CaregiverUserEntity> on success
  Future<Either<Failure, CaregiverUserEntity>> registerCaregiver(
    CaregiverSignUpCredentials credentials,
  );

  /// Sign out the current user
  /// Returns Either<Failure, Unit> on success (Unit = void in functional programming)
  Future<Either<Failure, Unit>> signOut();

  /// Get the current authenticated user
  /// Returns Either<Failure, UserEntity> if user is authenticated
  /// Returns AuthenticationFailure.unauthenticated if no user is signed in
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Send password reset email
  /// Returns Either<Failure, Unit> on success
  Future<Either<Failure, Unit>> sendPasswordResetEmail(
    PasswordResetCredentials credentials,
  );

  /// Verify email address
  /// Returns Either<Failure, Unit> on success
  Future<Either<Failure, Unit>> verifyEmail();

  /// Check if email is verified
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> isEmailVerified();

  /// Update user profile
  /// Returns Either<Failure, UserEntity> on success
  Future<Either<Failure, UserEntity>> updateProfile(
    String uid,
    Map<String, dynamic> updates,
  );

  /// Delete user account
  /// Returns Either<Failure, Unit> on success
  Future<Either<Failure, Unit>> deleteAccount(String uid);

  /// Stream of authentication state changes
  /// Emits UserEntity when user signs in, null when signs out
  Stream<Either<Failure, UserEntity?>> get authStateChanges;

  /// Re-authenticate user (for sensitive operations)
  /// Returns Either<Failure, Unit> on success
  Future<Either<Failure, Unit>> reauthenticate(String password);
}
