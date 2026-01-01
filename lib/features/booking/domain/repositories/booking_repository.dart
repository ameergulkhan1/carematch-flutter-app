import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/booking_entity.dart';

/// Abstract repository interface for booking management
/// This defines the contract that the data layer must implement
/// All methods return Either<Failure, Success> for error handling
abstract class BookingRepository {
  /// Create a new booking
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> createBooking(
    CreateBookingParams params,
  );

  /// Get a single booking by ID
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> getBooking(String bookingId);

  /// Get all bookings for a client
  /// Returns Either<Failure, List<BookingEntity>> on success
  /// Optional status filter
  Future<Either<Failure, List<BookingEntity>>> getClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  });

  /// Get all bookings for a caregiver
  /// Returns Either<Failure, List<BookingEntity>> on success
  /// Optional status filter
  Future<Either<Failure, List<BookingEntity>>> getCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  });

  /// Stream of client bookings (real-time updates)
  /// Emits List<BookingEntity> whenever bookings change
  Stream<Either<Failure, List<BookingEntity>>> watchClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  });

  /// Stream of caregiver bookings (real-time updates)
  /// Emits List<BookingEntity> whenever bookings change
  Stream<Either<Failure, List<BookingEntity>>> watchCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  });

  /// Update booking status
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> updateBookingStatus(
    UpdateBookingStatusParams params,
  );

  /// Cancel a booking
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> cancelBooking(
    String bookingId,
    String reason,
  );

  /// Accept a booking (caregiver)
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> acceptBooking(String bookingId);

  /// Reject a booking (caregiver)
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> rejectBooking(
    String bookingId,
    String reason,
  );

  /// Start a booking session
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> startSession(StartSessionParams params);

  /// End a booking session
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> endSession(EndSessionParams params);

  /// Complete a booking (client approval)
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> completeBooking(String bookingId);

  /// Raise a dispute
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> raiseDispute(
    String bookingId,
    String reason,
  );

  /// Resolve a dispute
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> resolveDispute(String bookingId);

  /// Request reschedule
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> requestReschedule(
    String bookingId,
    DateTime newStartDate,
    DateTime newEndDate,
  );

  /// Approve reschedule
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> approveReschedule(String bookingId);

  /// Reject reschedule
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> rejectReschedule(String bookingId);

  /// Update payment status
  /// Returns Either<Failure, BookingEntity> on success
  Future<Either<Failure, BookingEntity>> updatePaymentStatus(
    String bookingId,
    String paymentId,
    String paymentMethod,
    String transactionId,
  );

  /// Get booking statistics for a user
  /// Returns Either<Failure, Map<String, dynamic>> with stats
  Future<Either<Failure, Map<String, dynamic>>> getBookingStats(
    String userId,
    String userType, // 'client' or 'caregiver'
  );

  /// Search bookings by criteria
  /// Returns Either<Failure, List<BookingEntity>> on success
  Future<Either<Failure, List<BookingEntity>>> searchBookings({
    String? clientId,
    String? caregiverId,
    DateTime? startDate,
    DateTime? endDate,
    BookingStatus? status,
    ServiceType? serviceType,
  });
}
