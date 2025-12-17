import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';
import '../../../auth/domain/usecases/usecase.dart';

/// Create booking use case
class CreateBooking extends UseCase<BookingEntity, CreateBookingParams> {
  final BookingRepository repository;

  CreateBooking(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(CreateBookingParams params) async {
    return await repository.createBooking(params);
  }
}

/// Get booking by ID use case
class GetBooking extends UseCase<BookingEntity, String> {
  final BookingRepository repository;

  GetBooking(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(String bookingId) async {
    return await repository.getBooking(bookingId);
  }
}

/// Get client bookings parameters
class GetClientBookingsParams {
  final String clientId;
  final BookingStatus? statusFilter;

  GetClientBookingsParams({
    required this.clientId,
    this.statusFilter,
  });
}

/// Get client bookings use case
class GetClientBookings
    extends UseCase<List<BookingEntity>, GetClientBookingsParams> {
  final BookingRepository repository;

  GetClientBookings(this.repository);

  @override
  Future<Either<Failure, List<BookingEntity>>> call(
    GetClientBookingsParams params,
  ) async {
    return await repository.getClientBookings(
      params.clientId,
      statusFilter: params.statusFilter,
    );
  }
}

/// Get caregiver bookings parameters
class GetCaregiverBookingsParams {
  final String caregiverId;
  final BookingStatus? statusFilter;

  GetCaregiverBookingsParams({
    required this.caregiverId,
    this.statusFilter,
  });
}

/// Get caregiver bookings use case
class GetCaregiverBookings
    extends UseCase<List<BookingEntity>, GetCaregiverBookingsParams> {
  final BookingRepository repository;

  GetCaregiverBookings(this.repository);

  @override
  Future<Either<Failure, List<BookingEntity>>> call(
    GetCaregiverBookingsParams params,
  ) async {
    return await repository.getCaregiverBookings(
      params.caregiverId,
      statusFilter: params.statusFilter,
    );
  }
}

/// Watch client bookings use case (real-time)
class WatchClientBookings
    extends StreamUseCase<List<BookingEntity>, GetClientBookingsParams> {
  final BookingRepository repository;

  WatchClientBookings(this.repository);

  @override
  Stream<Either<Failure, List<BookingEntity>>> call(
    GetClientBookingsParams params,
  ) {
    return repository.watchClientBookings(
      params.clientId,
      statusFilter: params.statusFilter,
    );
  }
}

/// Watch caregiver bookings use case (real-time)
class WatchCaregiverBookings
    extends StreamUseCase<List<BookingEntity>, GetCaregiverBookingsParams> {
  final BookingRepository repository;

  WatchCaregiverBookings(this.repository);

  @override
  Stream<Either<Failure, List<BookingEntity>>> call(
    GetCaregiverBookingsParams params,
  ) {
    return repository.watchCaregiverBookings(
      params.caregiverId,
      statusFilter: params.statusFilter,
    );
  }
}

/// Update booking status use case
class UpdateBookingStatus
    extends UseCase<BookingEntity, UpdateBookingStatusParams> {
  final BookingRepository repository;

  UpdateBookingStatus(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(
    UpdateBookingStatusParams params,
  ) async {
    return await repository.updateBookingStatus(params);
  }
}

/// Cancel booking parameters
class CancelBookingParams {
  final String bookingId;
  final String reason;

  CancelBookingParams({required this.bookingId, required this.reason});
}

/// Cancel booking use case
class CancelBooking extends UseCase<BookingEntity, CancelBookingParams> {
  final BookingRepository repository;

  CancelBooking(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(CancelBookingParams params) async {
    return await repository.cancelBooking(params.bookingId, params.reason);
  }
}

/// Accept booking use case
class AcceptBooking extends UseCase<BookingEntity, String> {
  final BookingRepository repository;

  AcceptBooking(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(String bookingId) async {
    return await repository.acceptBooking(bookingId);
  }
}

/// Reject booking parameters
class RejectBookingParams {
  final String bookingId;
  final String reason;

  RejectBookingParams({required this.bookingId, required this.reason});
}

/// Reject booking use case
class RejectBooking extends UseCase<BookingEntity, RejectBookingParams> {
  final BookingRepository repository;

  RejectBooking(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(RejectBookingParams params) async {
    return await repository.rejectBooking(params.bookingId, params.reason);
  }
}

/// Start session use case
class StartSession extends UseCase<BookingEntity, StartSessionParams> {
  final BookingRepository repository;

  StartSession(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(StartSessionParams params) async {
    return await repository.startSession(params);
  }
}

/// End session use case
class EndSession extends UseCase<BookingEntity, EndSessionParams> {
  final BookingRepository repository;

  EndSession(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(EndSessionParams params) async {
    return await repository.endSession(params);
  }
}

/// Complete booking use case
class CompleteBooking extends UseCase<BookingEntity, String> {
  final BookingRepository repository;

  CompleteBooking(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(String bookingId) async {
    return await repository.completeBooking(bookingId);
  }
}

/// Raise dispute parameters
class RaiseDisputeParams {
  final String bookingId;
  final String reason;

  RaiseDisputeParams({required this.bookingId, required this.reason});
}

/// Raise dispute use case
class RaiseDispute extends UseCase<BookingEntity, RaiseDisputeParams> {
  final BookingRepository repository;

  RaiseDispute(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(RaiseDisputeParams params) async {
    return await repository.raiseDispute(params.bookingId, params.reason);
  }
}

/// Resolve dispute use case
class ResolveDispute extends UseCase<BookingEntity, String> {
  final BookingRepository repository;

  ResolveDispute(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(String bookingId) async {
    return await repository.resolveDispute(bookingId);
  }
}

/// Request reschedule parameters
class RequestRescheduleParams {
  final String bookingId;
  final DateTime newStartDate;
  final DateTime newEndDate;

  RequestRescheduleParams({
    required this.bookingId,
    required this.newStartDate,
    required this.newEndDate,
  });
}

/// Request reschedule use case
class RequestReschedule extends UseCase<BookingEntity, RequestRescheduleParams> {
  final BookingRepository repository;

  RequestReschedule(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(
    RequestRescheduleParams params,
  ) async {
    return await repository.requestReschedule(
      params.bookingId,
      params.newStartDate,
      params.newEndDate,
    );
  }
}

/// Get booking stats parameters
class GetBookingStatsParams {
  final String userId;
  final String userType; // 'client' or 'caregiver'

  GetBookingStatsParams({required this.userId, required this.userType});
}

/// Get booking stats use case
class GetBookingStats
    extends UseCase<Map<String, dynamic>, GetBookingStatsParams> {
  final BookingRepository repository;

  GetBookingStats(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    GetBookingStatsParams params,
  ) async {
    return await repository.getBookingStats(params.userId, params.userType);
  }
}
