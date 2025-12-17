import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

/// Base use case interface
/// All use cases should extend this and implement the call method
/// Type - return type of the use case
/// Params - parameters passed to the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case with no parameters
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Stream use case (for real-time data)
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Stream use case with no parameters
abstract class StreamUseCaseNoParams<Type> {
  Stream<Either<Failure, Type>> call();
}
