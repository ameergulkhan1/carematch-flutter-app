import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

/// @deprecated Use EnhancedBookingService instead
/// This service will be removed in a future version
/// Old booking service - replaced by EnhancedBookingService which implements the full 13-stage booking flow
@Deprecated('Use EnhancedBookingService instead. This will be removed in a future version.')
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new booking
  Future<String?> createBooking(BookingModel booking) async {
    try {
      final docRef = await _firestore.collection('bookings').add(booking.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  // Get bookings for a client
  Stream<List<BookingModel>> getClientBookings(String clientId, {BookingStatus? statusFilter}) {
    Query query = _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get bookings for a caregiver
  Stream<List<BookingModel>> getCaregiverBookings(String caregiverId, {BookingStatus? statusFilter}) {
    Query query = _firestore
        .collection('bookings')
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get single booking
  Future<BookingModel?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };

      if (status == BookingStatus.confirmed) {
        updates['confirmedAt'] = FieldValue.serverTimestamp();
      } else if (status == BookingStatus.completed) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      } else if (status == BookingStatus.cancelled) {
        updates['cancelledAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  // Reject booking (caregiver rejects)
  Future<bool> rejectBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.rejected.name,
        'rejectionReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error rejecting booking: $e');
      return false;
    }
  }

  // Get active bookings count for client
  Future<int> getActiveBookingsCount(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('status', whereIn: ['pending', 'confirmed', 'inProgress'])
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active bookings count: $e');
      return 0;
    }
  }

  // Get completed bookings count for client
  Future<int> getCompletedBookingsCount(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'completed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting completed bookings count: $e');
      return 0;
    }
  }

  // Get upcoming bookings (next 7 days)
  Future<List<BookingModel>> getUpcomingBookings(String clientId) async {
    try {
      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('status', whereIn: ['confirmed', 'pending'])
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(weekFromNow))
          .orderBy('startDate')
          .get();

      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('Error getting upcoming bookings: $e');
      return [];
    }
  }

  // Mark booking as paid
  Future<bool> markAsPaid(String bookingId, String paymentId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'isPaid': true,
        'paymentId': paymentId,
      });
      return true;
    } catch (e) {
      print('Error marking booking as paid: $e');
      return false;
    }
  }
}
