import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/auth_credentials.dart';
import '../repositories/auth_repository.dart';
import 'usecase.dart';

/// Sign in use case
class SignIn extends UseCase<UserEntity, SignInCredentials> {
  final AuthRepository repository;

  SignIn(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInCredentials params) async {
    return await repository.signIn(params);
  }
}

/// Register client use case
class RegisterClient
    extends UseCase<ClientUserEntity, ClientSignUpCredentials> {
  final AuthRepository repository;

  RegisterClient(this.repository);

  @override
  Future<Either<Failure, ClientUserEntity>> call(
    ClientSignUpCredentials params,
  ) async {
    return await repository.registerClient(params);
  }
}

/// Register caregiver use case
class RegisterCaregiver
    extends UseCase<CaregiverUserEntity, CaregiverSignUpCredentials> {
  final AuthRepository repository;

  RegisterCaregiver(this.repository);

  @override
  Future<Either<Failure, CaregiverUserEntity>> call(
    CaregiverSignUpCredentials params,
  ) async {
    return await repository.registerCaregiver(params);
  }
}

/// Sign out use case
class SignOut extends UseCaseNoParams<Unit> {
  final AuthRepository repository;

  SignOut(this.repository);

  @override
  Future<Either<Failure, Unit>> call() async {
    return await repository.signOut();
  }
}

/// Get current user use case
class GetCurrentUser extends UseCaseNoParams<UserEntity> {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call() async {
    return await repository.getCurrentUser();
  }
}

/// Send password reset email use case
class SendPasswordResetEmail extends UseCase<Unit, PasswordResetCredentials> {
  final AuthRepository repository;

  SendPasswordResetEmail(this.repository);

  @override
  Future<Either<Failure, Unit>> call(PasswordResetCredentials params) async {
    return await repository.sendPasswordResetEmail(params);
  }
}

/// Verify email use case
class VerifyEmail extends UseCaseNoParams<Unit> {
  final AuthRepository repository;

  VerifyEmail(this.repository);

  @override
  Future<Either<Failure, Unit>> call() async {
    return await repository.verifyEmail();
  }
}

/// Check email verification status use case
class IsEmailVerified extends UseCaseNoParams<bool> {
  final AuthRepository repository;

  IsEmailVerified(this.repository);

  @override
  Future<Either<Failure, bool>> call() async {
    return await repository.isEmailVerified();
  }
}

/// Update profile parameters
class UpdateProfileParams {
  final String uid;
  final Map<String, dynamic> updates;

  UpdateProfileParams({required this.uid, required this.updates});
}

/// Update profile use case
class UpdateProfile extends UseCase<UserEntity, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(params.uid, params.updates);
  }
}

/// Delete account use case
class DeleteAccount extends UseCase<Unit, String> {
  final AuthRepository repository;

  DeleteAccount(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String uid) async {
    return await repository.deleteAccount(uid);
  }
}

/// Watch auth state changes use case
class WatchAuthStateChanges extends StreamUseCaseNoParams<UserEntity?> {
  final AuthRepository repository;

  WatchAuthStateChanges(this.repository);

  @override
  Stream<Either<Failure, UserEntity?>> call() {
    return repository.authStateChanges;
  }
}

/// Re-authenticate use case
class Reauthenticate extends UseCase<Unit, String> {
  final AuthRepository repository;

  Reauthenticate(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String password) async {
    return await repository.reauthenticate(password);
  }
}
