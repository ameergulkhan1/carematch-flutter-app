import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/booking_model.dart';
import '../../domain/entities/booking_entity.dart';

/// Remote data source for booking operations
/// All Firestore booking operations happen here
/// Throws exceptions on error (converted to Failures in repository)
abstract class BookingRemoteDataSource {
  /// Create a new booking
  Future<BookingModel> createBooking(CreateBookingParams params);

  /// Get a booking by ID
  Future<BookingModel> getBooking(String bookingId);

  /// Get client bookings
  Future<List<BookingModel>> getClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  });

  /// Get caregiver bookings
  Future<List<BookingModel>> getCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  });

  /// Stream of client bookings
  Stream<List<BookingModel>> watchClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  });

  /// Stream of caregiver bookings
  Stream<List<BookingModel>> watchCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  });

  /// Update booking status
  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
    String? reason,
  );

  /// Start a session
  Future<BookingModel> startSession(String bookingId, DateTime startTime);

  /// End a session
  Future<BookingModel> endSession(
    String bookingId,
    DateTime endTime,
    List<String> sessionPhotos,
    String? sessionNotes,
    List<String> completedTasks,
  );

  /// Update payment status
  Future<BookingModel> updatePaymentStatus(
    String bookingId,
    String paymentId,
    String paymentMethod,
    String transactionId,
  );

  /// Get booking statistics
  Future<Map<String, dynamic>> getBookingStats(String userId, String userType);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore _firestore;

  BookingRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<BookingModel> createBooking(CreateBookingParams params) async {
    try {
      // Calculate amounts
      final totalAmount = params.hourlyRate * params.totalHours;
      final platformFee = totalAmount * 0.15; // 15% platform fee
      final finalAmount = totalAmount + platformFee;

      // Generate booking request ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bookingRequestId = 'BKG-${DateTime.now().year}-${timestamp.toString().substring(timestamp.toString().length - 6)}';

      final bookingData = {
        'bookingRequestId': bookingRequestId,
        'clientId': params.clientId,
        'clientName': params.clientName,
        'caregiverId': params.caregiverId,
        'caregiverName': params.caregiverName,
        'caregiverImageUrl': params.caregiverImageUrl,
        'startDate': Timestamp.fromDate(params.startDate),
        'endDate': Timestamp.fromDate(params.endDate),
        'startTime': params.startTime,
        'endTime': params.endTime,
        'bookingType': params.bookingType.name,
        'serviceType': params.serviceType.name,
        'services': params.services,
        'specialRequirements': params.specialRequirements,
        'tasks': params.tasks,
        'medicationRequired': params.medicationRequired,
        'mobilityHelpRequired': params.mobilityHelpRequired,
        'mealPrepRequired': params.mealPrepRequired,
        'schoolPickupRequired': params.schoolPickupRequired,
        'carePlanDetails': params.carePlanDetails,
        'hourlyRate': params.hourlyRate,
        'totalHours': params.totalHours,
        'totalAmount': totalAmount,
        'platformFee': platformFee,
        'finalAmount': finalAmount,
        'status': BookingStatus.pending.name,
        'requestMessage': params.requestMessage,
        'createdAt': FieldValue.serverTimestamp(),
        'isPaid': false,
        'sessionPhotos': [],
        'completedTasks': [],
        'isReviewed': false,
      };

      final docRef = await _firestore.collection('bookings').add(bookingData);
      final doc = await docRef.get();

      return BookingModel.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw ServerException(message: 'Failed to create booking: ${e.toString()}');
    }
  }

  @override
  Future<BookingModel> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) {
        throw ServerException.notFound();
      }

      return BookingModel.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get booking: ${e.toString()}');
    }
  }

  @override
  Future<List<BookingModel>> getClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  }) async {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get client bookings: ${e.toString()}');
    }
  }

  @override
  Future<List<BookingModel>> getCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  }) async {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('caregiverId', isEqualTo: caregiverId)
          .orderBy('createdAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get caregiver bookings: ${e.toString()}');
    }
  }

  @override
  Stream<List<BookingModel>> watchClientBookings(
    String clientId, {
    BookingStatus? statusFilter,
  }) {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      throw ServerException(message: 'Failed to watch client bookings: ${e.toString()}');
    }
  }

  @override
  Stream<List<BookingModel>> watchCaregiverBookings(
    String caregiverId, {
    BookingStatus? statusFilter,
  }) {
    try {
      Query query = _firestore
          .collection('bookings')
          .where('caregiverId', isEqualTo: caregiverId)
          .orderBy('createdAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      throw ServerException(message: 'Failed to watch caregiver bookings: ${e.toString()}');
    }
  }

  @override
  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
    String? reason,
  ) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };

      // Add timestamp based on status
      switch (status) {
        case BookingStatus.confirmed:
          updates['confirmedAt'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.completed:
          updates['completedAt'] = FieldValue.serverTimestamp();
          break;
        case BookingStatus.cancelled:
          updates['cancelledAt'] = FieldValue.serverTimestamp();
          if (reason != null) updates['cancellationReason'] = reason;
          break;
        case BookingStatus.rejected:
          if (reason != null) updates['rejectionReason'] = reason;
          break;
        case BookingStatus.disputed:
          updates['disputedAt'] = FieldValue.serverTimestamp();
          if (reason != null) updates['disputeReason'] = reason;
          break;
        case BookingStatus.pendingPayment:
          updates['pendingPaymentAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      return await getBooking(bookingId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to update booking status: ${e.toString()}');
    }
  }

  @override
  Future<BookingModel> startSession(String bookingId, DateTime startTime) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.inProgress.name,
        'sessionStartedAt': Timestamp.fromDate(startTime),
      });

      return await getBooking(bookingId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to start session: ${e.toString()}');
    }
  }

  @override
  Future<BookingModel> endSession(
    String bookingId,
    DateTime endTime,
    List<String> sessionPhotos,
    String? sessionNotes,
    List<String> completedTasks,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'sessionEndedAt': Timestamp.fromDate(endTime),
        'sessionPhotos': sessionPhotos,
        'sessionNotes': sessionNotes,
        'completedTasks': completedTasks,
      });

      return await getBooking(bookingId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to end session: ${e.toString()}');
    }
  }

  @override
  Future<BookingModel> updatePaymentStatus(
    String bookingId,
    String paymentId,
    String paymentMethod,
    String transactionId,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'isPaid': true,
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'paymentTransactionId': transactionId,
        'status': BookingStatus.confirmed.name,
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      return await getBooking(bookingId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to update payment status: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getBookingStats(String userId, String userType) async {
    try {
      final field = userType == 'client' ? 'clientId' : 'caregiverId';

      final allBookings = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .get();

      final total = allBookings.docs.length;
      final completed =
          allBookings.docs.where((doc) => doc.data()['status'] == BookingStatus.completed.name).length;
      final cancelled =
          allBookings.docs.where((doc) => doc.data()['status'] == BookingStatus.cancelled.name).length;
      final inProgress =
          allBookings.docs.where((doc) => doc.data()['status'] == BookingStatus.inProgress.name).length;
      final pending =
          allBookings.docs.where((doc) => doc.data()['status'] == BookingStatus.pending.name).length;

      double totalEarnings = 0.0;
      if (userType == 'caregiver') {
        for (final doc in allBookings.docs) {
          final data = doc.data();
          if (data['status'] == BookingStatus.completed.name && data['isPaid'] == true) {
            final totalAmount = (data['totalAmount'] ?? 0).toDouble();
            totalEarnings += totalAmount * 0.85; // After 15% platform fee
          }
        }
      }

      return {
        'total': total,
        'completed': completed,
        'cancelled': cancelled,
        'inProgress': inProgress,
        'pending': pending,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      throw ServerException(message: 'Failed to get booking stats: ${e.toString()}');
    }
  }
}
