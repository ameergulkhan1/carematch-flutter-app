import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:carematch_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:carematch_app/features/auth/domain/entities/user_entity.dart';
import 'package:carematch_app/features/auth/domain/entities/auth_credentials.dart';
import 'package:carematch_app/core/errors/failures.dart';
import '../../../../helpers/test_helper.mocks.dart';

void main() {
  late SignIn usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignIn(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tCredentials = SignInCredentials(
    email: tEmail,
    password: tPassword,
  );

  final tUser = ClientUserEntity(
    uid: '123',
    email: tEmail,
    fullName: 'Test User',
    phoneNumber: '+1234567890',
    isEmailVerified: true,
    createdAt: DateTime(2024, 1, 1),
  );

  test('should get user entity from repository', () async {
    // arrange
    when(mockAuthRepository.signIn(any))
        .thenAnswer((_) async => Right(tUser));

    // act
    final result = await usecase(tCredentials);

    // assert
    expect(result, Right(tUser));
    verify(mockAuthRepository.signIn(tCredentials));
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthenticationFailure when sign in fails', () async {
    // arrange
    when(mockAuthRepository.signIn(any))
        .thenAnswer((_) async => Left(AuthenticationFailure.invalidCredentials()));

    // act
    final result = await usecase(tCredentials);

    // assert
    expect(result, Left(AuthenticationFailure.invalidCredentials()));
    verify(mockAuthRepository.signIn(tCredentials));
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
