import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository
/// Handles errors and converts exceptions to failures
/// Returns Either<Failure, Success> to domain layer
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> signIn(
      SignInCredentials credentials) async {
    try {
      final userModel =
          await remoteDataSource.signInWithEmailAndPassword(credentials);
      return Right(userModel);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClientUserEntity>> registerClient(
    ClientSignUpCredentials credentials,
  ) async {
    try {
      final userModel = await remoteDataSource.registerClient(credentials);
      return Right(userModel);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CaregiverUserEntity>> registerCaregiver(
    CaregiverSignUpCredentials credentials,
  ) async {
    try {
      final userModel = await remoteDataSource.registerCaregiver(credentials);
      return Right(userModel);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final firebaseUser = remoteDataSource.getCurrentFirebaseUser();

      if (firebaseUser == null) {
        return Left(AuthenticationFailure.unauthenticated());
      }

      final userData =
          await remoteDataSource.getCurrentUserData(firebaseUser.uid);

      if (userData == null) {
        return Left(ServerFailure.notFound());
      }

      final role = userData['role'] as String?;

      if (role == 'client') {
        return Right(ClientUserModel.fromJson(userData));
      } else if (role == 'caregiver') {
        return Right(CaregiverUserModel.fromJson(userData));
      } else {
        return const Left(ServerFailure(message: 'Unknown user role'));
      }
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(
    PasswordResetCredentials credentials,
  ) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(credentials.email);
      return const Right(unit);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyEmail() async {
    try {
      await remoteDataSource.verifyEmail();
      return const Right(unit);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      final isVerified = await remoteDataSource.isEmailVerified();
      return Right(isVerified);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      final userData = await remoteDataSource.updateUserProfile(uid, updates);

      final role = userData['role'] as String?;

      if (role == 'client') {
        return Right(ClientUserModel.fromJson(userData));
      } else if (role == 'caregiver') {
        return Right(CaregiverUserModel.fromJson(userData));
      } else {
        return const Left(ServerFailure(message: 'Unknown user role'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount(String uid) async {
    try {
      await remoteDataSource.deleteAccount(uid);
      return const Right(unit);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserEntity?>> get authStateChanges {
    return remoteDataSource.authStateChanges.asyncMap((firebaseUser) async {
      try {
        if (firebaseUser == null) {
          return const Right<Failure, UserEntity?>(null);
        }

        final userData =
            await remoteDataSource.getCurrentUserData(firebaseUser.uid);

        if (userData == null) {
          return const Right<Failure, UserEntity?>(null);
        }

        final role = userData['role'] as String?;

        if (role == 'client') {
          final user = ClientUserModel.fromJson(userData);
          return Right<Failure, UserEntity?>(user);
        } else if (role == 'caregiver') {
          final user = CaregiverUserModel.fromJson(userData);
          return Right<Failure, UserEntity?>(user);
        } else {
          return const Left<Failure, UserEntity?>(
            ServerFailure(message: 'Unknown user role'),
          );
        }
      } catch (e) {
        return Left<Failure, UserEntity?>(
          UnknownFailure(message: e.toString()),
        );
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> reauthenticate(String password) async {
    try {
      await remoteDataSource.reauthenticate(password);
      return const Right(unit);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
