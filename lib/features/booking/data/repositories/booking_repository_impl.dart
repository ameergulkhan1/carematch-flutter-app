import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/booking_model.dart';

/// Implementation of BookingRepository
/// Handles errors and converts exceptions to failures
/// Returns Either<Failure, Success> to domain layer
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BookingEntity>> createBooking(
    CreateBookingParams params,
  ) async {
    try {
      final bookingModel = await remoteDataSource.createBooking(params);
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBooking(String bookingId) async {
    try {
      final bookingModel = await remoteDataSource.getBooking(bookingId);
      return Right(bookingModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  }) async {
    try {
      final bookingModels = await remoteDataSource.getClientBookings(
        clientId,
        statusFilter: statusFilter,
      );
      return Right(bookingModels);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  }) async {
    try {
      final bookingModels = await remoteDataSource.getCaregiverBookings(
        caregiverId,
        statusFilter: statusFilter,
      );
      return Right(bookingModels);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<BookingEntity>>> watchClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  }) {
    return remoteDataSource
        .watchClientBookings(clientId, statusFilter: statusFilter)
        .map<Either<Failure, List<BookingEntity>>>(
          (bookingModels) => Right(bookingModels),
        )
        .handleError((error) {
      if (error is ServerException) {
        return Left<Failure, List<BookingEntity>>(
          ServerFailure(message: error.message),
        );
      } else if (error is NetworkException) {
        return Left<Failure, List<BookingEntity>>(
          NetworkFailure(message: error.message),
        );
      } else {
        return Left<Failure, List<BookingEntity>>(
          UnknownFailure(message: error.toString()),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, List<BookingEntity>>> watchCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  }) {
    return remoteDataSource
        .watchCaregiverBookings(caregiverId, statusFilter: statusFilter)
        .map<Either<Failure, List<BookingEntity>>>(
          (bookingModels) => Right(bookingModels),
        )
        .handleError((error) {
      if (error is ServerException) {
        return Left<Failure, List<BookingEntity>>(
          ServerFailure(message: error.message),
        );
      } else if (error is NetworkException) {
        return Left<Failure, List<BookingEntity>>(
          NetworkFailure(message: error.message),
        );
      } else {
        return Left<Failure, List<BookingEntity>>(
          UnknownFailure(message: error.toString()),
        );
      }
    });
  }

  @override
  Future<Either<Failure, BookingEntity>> updateBookingStatus(
    UpdateBookingStatusParams params,
  ) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        params.bookingId,
        params.newStatus,
        params.reason,
      );
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(
    String bookingId,
    String cancellationReason,
  ) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.cancelled,
        cancellationReason,
      );
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> acceptBooking(String bookingId) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.confirmed,
        null,
      );
      return Right(bookingModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> rejectBooking(
    String bookingId,
    String rejectionReason,
  ) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.rejected,
        rejectionReason,
      );
      return Right(bookingModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> startSession(
    StartSessionParams params,
  ) async {
    try {
      final bookingModel = await remoteDataSource.startSession(
        params.bookingId,
        params.startTime,
      );
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> endSession(
    EndSessionParams params,
  ) async {
    try {
      final bookingModel = await remoteDataSource.endSession(
        params.bookingId,
        params.endTime,
        params.sessionPhotos,
        params.sessionNotes,
        params.completedTasks,
      );
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> completeBooking(String bookingId) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.completed,
        null,
      );
      return Right(bookingModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> raiseDispute(
    String bookingId,
    String disputeReason,
  ) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.disputed,
        disputeReason,
      );
      return Right(bookingModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> resolveDispute(String bookingId) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.completed,
        'Dispute resolved by admin',
      );
      return Right(bookingModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> requestReschedule(
    String bookingId,
    DateTime newStartDate,
    DateTime newEndDate,
  ) async {
    try {
      // For now, just update status to pending (would need custom datasource method for full implementation)
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.pending,
        'Reschedule requested: ${newStartDate.toString()} to ${newEndDate.toString()}',
      );
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> approveReschedule(
    String bookingId,
  ) async {
    try {
      // Approve by setting back to confirmed
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.confirmed,
        'Reschedule approved',
      );
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> rejectReschedule(
    String bookingId,
  ) async {
    try {
      final bookingModel = await remoteDataSource.updateBookingStatus(
        bookingId,
        BookingStatus.confirmed,
        'Reschedule request rejected',
      );
      return Right(bookingModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> updatePaymentStatus(
    String bookingId,
    String paymentId,
    String paymentMethod,
    String transactionId,
  ) async {
    try {
      final bookingModel = await remoteDataSource.updatePaymentStatus(
        bookingId,
        paymentId,
        paymentMethod,
        transactionId,
      );
      return Right(bookingModel);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBookingStats(
    String userId,
    String userType,
  ) async {
    try {
      final stats = await remoteDataSource.getBookingStats(userId, userType);
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> searchBookings({
    String? clientId,
    String? caregiverId,
    DateTime? startDate,
    DateTime? endDate,
    BookingStatus? status,
    ServiceType? serviceType,
  }) async {
    try {
      List<BookingModel> allBookings = [];
      
      if (clientId != null) {
        allBookings = await remoteDataSource.getClientBookings(clientId, statusFilter: status);
      } else if (caregiverId != null) {
        allBookings = await remoteDataSource.getCaregiverBookings(caregiverId, statusFilter: status);
      } else {
        return const Left(ValidationFailure(
          message: 'Either clientId or caregiverId must be provided',
        ));
      }

      // Filter bookings based on search criteria
      var searchResults = allBookings.where((booking) {
        bool matches = true;
        
        if (startDate != null && booking.startDate.isBefore(startDate)) {
          matches = false;
        }
        
        if (endDate != null && booking.endDate.isAfter(endDate)) {
          matches = false;
        }
        
        if (serviceType != null && booking.serviceType != serviceType) {
          matches = false;
        }
        
        return matches;
      }).toList();

      return Right(searchResults);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
