import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Enhanced Booking Service implementing 13-stage booking flow
/// 
/// Stage 1-2: Booking Request Creation
/// Stage 3-5: Caregiver Response & Acceptance
/// Stage 6: Payment Processing
/// Stage 7: Booking Confirmation  
/// Stage 8: Pre-Service Reminders
/// Stage 9: Service Execution
/// Stage 10: Post-Service Review
/// Stage 11: Payout to Caregiver
/// Stage 12: Review & Rating
/// Stage 13: Admin Oversight
class EnhancedBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ==================== STAGE 1-2: BOOKING REQUEST CREATION ====================
  
  /// Create a new booking request (Stage 1-2)
  /// Generates booking request ID and creates initial booking
  Future<String?> createBookingRequest({
    required String clientId,
    required String clientName,
    required String caregiverId,
    required String caregiverName,
    String? caregiverImageUrl,
    required DateTime startDate,
    required DateTime endDate,
    String? startTime,
    String? endTime,
    required BookingType bookingType,
    required ServiceType serviceType,
    required List<String> services,
    String? specialRequirements,
    List<String>? tasks,
    bool medicationRequired = false,
    bool mobilityHelpRequired = false,
    bool mealPrepRequired = false,
    bool schoolPickupRequired = false,
    String? carePlanDetails,
    required double hourlyRate,
    required int totalHours,
    Map<String, dynamic>? clientAddress,
    String? clientPhone,
    String? clientPhoneCountryCode,
    String? clientPhoneDialCode,
    String? caregiverPhone,
    String? caregiverPhoneCountryCode,
    String? caregiverPhoneDialCode,
    String? requestMessage,
  }) async {
    try {
      // Calculate costs
      final totalAmount = hourlyRate * totalHours;
      final platformFee = totalAmount * 0.15; // 15% platform fee
      final finalAmount = totalAmount + platformFee;

      // Generate booking request ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final year = DateTime.now().year;
      final bookingRequestId = 'BKG-$year-${timestamp.toString().substring(7)}';

      final booking = BookingModel(
        id: '', // Will be set by Firestore
        bookingRequestId: bookingRequestId,
        clientId: clientId,
        clientName: clientName,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        caregiverImageUrl: caregiverImageUrl,
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        bookingType: bookingType,
        serviceType: serviceType,
        services: services,
        specialRequirements: specialRequirements,
        tasks: tasks ?? [],
        medicationRequired: medicationRequired,
        mobilityHelpRequired: mobilityHelpRequired,
        mealPrepRequired: mealPrepRequired,
        schoolPickupRequired: schoolPickupRequired,
        carePlanDetails: carePlanDetails,
        hourlyRate: hourlyRate,
        totalHours: totalHours,
        totalAmount: totalAmount,
        platformFee: platformFee,
        finalAmount: finalAmount,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        requestMessage: requestMessage,
        clientAddress: clientAddress,
        clientPhone: clientPhone,
        clientPhoneCountryCode: clientPhoneCountryCode,
        clientPhoneDialCode: clientPhoneDialCode,
        caregiverPhone: caregiverPhone,
        caregiverPhoneCountryCode: caregiverPhoneCountryCode,
        caregiverPhoneDialCode: caregiverPhoneDialCode,
      );

      final docRef = await _firestore.collection('bookings').add(booking.toMap());

      // Send notification to caregiver (Stage 3)
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: caregiverId,
          type: NotificationType.general,
          title: '🔔 New Booking Request',
          message: '$clientName has requested your services for ${serviceType.name}. Starting ${_formatDate(startDate)}.',
          data: {'bookingId': docRef.id, 'bookingRequestId': bookingRequestId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return docRef.id;
    } catch (e) {
      print('Error creating booking request: $e');
      return null;
    }
  }

  // ==================== STAGE 3-5: CAREGIVER RESPONSE ====================

  /// Accept booking request (Stage 5)
  /// Moves booking to pending payment status
  Future<bool> acceptBookingRequest(String bookingId, String caregiverId) async {
    try {
      print('🔵 Accepting booking: $bookingId for caregiver: $caregiverId');
      
      final booking = await getBooking(bookingId);
      if (booking == null) {
        print('❌ Booking not found');
        return false;
      }
      
      if (booking.caregiverId != caregiverId) {
        print('❌ Caregiver ID mismatch. Expected: ${booking.caregiverId}, Got: $caregiverId');
        return false;
      }

      // Validate caregiver availability (exclude current booking from check)
      print('🔵 Checking caregiver availability...');
      final isAvailable = await _checkCaregiverAvailability(
        caregiverId,
        booking.startDate,
        booking.endDate,
        excludeBookingId: bookingId,
      );

      if (!isAvailable) {
        print('❌ Caregiver not available for this time slot');
        return false;
      }

      print('🔵 Updating booking status to pendingPayment...');
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.pendingPayment.name,
        'acceptedAt': FieldValue.serverTimestamp(),
        'pendingPaymentAt': FieldValue.serverTimestamp(),
      });

      // Notify client to proceed with payment
      print('🔵 Sending notification to client...');
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.clientId,
          type: NotificationType.bookingConfirmed,
          title: '✅ Booking Accepted',
          message: '${booking.caregiverName} accepted your booking request. Please proceed to payment.',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      print('✅ Booking accepted successfully!');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error accepting booking: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Reject booking request (Stage 5)
  Future<bool> rejectBookingRequest(String bookingId, String caregiverId, String reason) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.caregiverId != caregiverId) {
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.rejected.name,
        'rejectionReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Notify client
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.clientId,
          type: NotificationType.bookingCancelled,
          title: '❌ Booking Declined',
          message: '${booking.caregiverName} declined your booking request.',
          data: {'bookingId': bookingId, 'reason': reason},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error rejecting booking: $e');
      return false;
    }
  }

  // ==================== STAGE 6: PAYMENT PROCESSING ====================

  /// Process payment and confirm booking (Stage 6-7)
  Future<bool> processPayment({
    required String bookingId,
    required String clientId,
    required String paymentMethod,
    required String paymentTransactionId,
  }) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.clientId != clientId) {
        return false;
      }

      // Update booking with payment info
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.confirmed.name,
        'isPaid': true,
        'paymentMethod': paymentMethod,
        'paymentTransactionId': paymentTransactionId,
        'paymentId': paymentTransactionId,
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      // Notify both parties
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.clientId,
          type: NotificationType.paymentReceived,
          title: '💳 Payment Successful',
          message: 'Your booking is confirmed! ${booking.caregiverName} will arrive on ${_formatDate(booking.startDate)}.',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.caregiverId,
          type: NotificationType.bookingConfirmed,
          title: '🎉 Booking Confirmed',
          message: 'Payment received for booking with ${booking.clientName}. Session starts ${_formatDate(booking.startDate)}.',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  // ==================== STAGE 8: REMINDERS ====================

  /// Schedule reminder notifications (Called by backend scheduler)
  Future<void> sendReminders(String bookingId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null) return;

      final now = DateTime.now();
      final timeUntilStart = booking.startDate.difference(now);

      String reminderMessage = '';
      if (timeUntilStart.inHours <= 2) {
        reminderMessage = 'Your session starts in ${timeUntilStart.inHours} hours';
      } else if (timeUntilStart.inHours <= 24) {
        reminderMessage = 'Your session starts tomorrow';
      }

      if (reminderMessage.isNotEmpty) {
        // Notify client
        await _notificationService.createNotification(
          NotificationModel(
            id: '',
            userId: booking.clientId,
            type: NotificationType.sessionReminder,
            title: '⏰ Upcoming Session',
            message: '$reminderMessage at ${booking.startTime ?? "scheduled time"}',
            data: {'bookingId': bookingId},
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );

        // Notify caregiver
        await _notificationService.createNotification(
          NotificationModel(
            id: '',
            userId: booking.caregiverId,
            type: NotificationType.sessionReminder,
            title: '⏰ Upcoming Session',
            message: '$reminderMessage with ${booking.clientName}',
            data: {'bookingId': bookingId},
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('Error sending reminders: $e');
    }
  }

  // ==================== STAGE 9: SERVICE EXECUTION ====================

  /// Start service session (Stage 9)
  Future<bool> startSession(String bookingId, String caregiverId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.caregiverId != caregiverId) {
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.inProgress.name,
        'sessionStartedAt': FieldValue.serverTimestamp(),
      });

      // Notify client
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.clientId,
          type: NotificationType.general,
          title: '▶️ Session Started',
          message: '${booking.caregiverName} has started the care session.',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error starting session: $e');
      return false;
    }
  }

  /// Log task completion during session
  Future<bool> logTaskCompletion(String bookingId, String taskName, String caregiverId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.caregiverId != caregiverId) {
        return false;
      }

      final taskLog = {
        'task': taskName,
        'completed': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('bookings').doc(bookingId).update({
        'taskCompletionLogs': FieldValue.arrayUnion([taskLog]),
      });

      return true;
    } catch (e) {
      print('Error logging task: $e');
      return false;
    }
  }

  /// Add session photo
  Future<bool> addSessionPhoto(String bookingId, String photoUrl, String caregiverId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.caregiverId != caregiverId) {
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'sessionPhotos': FieldValue.arrayUnion([photoUrl]),
      });

      return true;
    } catch (e) {
      print('Error adding photo: $e');
      return false;
    }
  }

  /// Add session notes
  Future<bool> addSessionNotes(String bookingId, String notes, String caregiverId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.caregiverId != caregiverId) {
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'sessionNotes': notes,
      });

      return true;
    } catch (e) {
      print('Error adding notes: $e');
      return false;
    }
  }

  /// End service session (Stage 9)
  Future<bool> endSession(String bookingId, String caregiverId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.caregiverId != caregiverId) {
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'sessionEndedAt': FieldValue.serverTimestamp(),
        'clientApprovalStatus': 'pending',
      });

      // Notify client to review session
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.clientId,
          type: NotificationType.bookingCompleted,
          title: '✅ Session Completed',
          message: 'Please review the session summary and approve or report any issues.',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error ending session: $e');
      return false;
    }
  }

  // ==================== STAGE 10: POST-SERVICE REVIEW ====================

  /// Client approves session (Stage 10)
  Future<bool> approveSession(String bookingId, String clientId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.clientId != clientId) {
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.completed.name,
        'clientApprovalStatus': 'approved',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Trigger payout process (Stage 11)
      await releasePayoutToCaregiver(bookingId);

      return true;
    } catch (e) {
      print('Error approving session: $e');
      return false;
    }
  }

  /// Client disputes session (Stage 10)
  Future<bool> disputeSession(String bookingId, String clientId, String disputeReason) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.clientId != clientId) {
        return false;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.disputed.name,
        'clientApprovalStatus': 'disputed',
        'disputeReason': disputeReason,
        'disputedAt': FieldValue.serverTimestamp(),
      });

      // Notify admin for intervention
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: 'admin', // Admin notification
          type: NotificationType.general,
          title: '⚠️ Dispute Raised',
          message: 'Booking ${booking.bookingRequestId} has been disputed by ${booking.clientName}.',
          data: {'bookingId': bookingId, 'reason': disputeReason},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error disputing session: $e');
      return false;
    }
  }

  // ==================== STAGE 11: PAYOUT ====================

  /// Release payout to caregiver (Stage 11)
  Future<bool> releasePayoutToCaregiver(String bookingId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null || booking.status != BookingStatus.completed) {
        return false;
      }

      // Calculate caregiver earnings (platform takes fee)
      final caregiverEarnings = booking.totalAmount;
      
      // Create wallet transaction
      final walletTransactionId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore.collection('wallet_transactions').add({
        'caregiverId': booking.caregiverId,
        'bookingId': bookingId,
        'amount': caregiverEarnings,
        'type': 'booking_payment',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update caregiver wallet balance
      await _firestore.collection('users').doc(booking.caregiverId).update({
        'walletBalance': FieldValue.increment(caregiverEarnings),
      });

      // Update booking
      await _firestore.collection('bookings').doc(bookingId).update({
        'payoutReleased': true,
        'walletTransactionId': walletTransactionId,
        'payoutReleasedAt': FieldValue.serverTimestamp(),
      });

      // Notify caregiver
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.caregiverId,
          type: NotificationType.paymentReceived,
          title: '💰 Payment Received',
          message: '\$${caregiverEarnings.toStringAsFixed(2)} has been added to your wallet.',
          data: {'bookingId': bookingId, 'amount': caregiverEarnings.toString()},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error releasing payout: $e');
      return false;
    }
  }

  // ==================== STAGE 13: ADMIN OVERSIGHT ====================

  /// Admin resolves dispute (Stage 13)
  Future<bool> resolveDispute({
    required String bookingId,
    required String adminId,
    required String resolution,
    required bool refundToClient,
    String? adminNotes,
  }) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null) return false;

      final updates = <String, dynamic>{
        'status': BookingStatus.resolved.name,
        'adminReviewedBy': adminId,
        'adminNotes': adminNotes ?? resolution,
        'adminReviewedAt': FieldValue.serverTimestamp(),
      };

      if (refundToClient) {
        // Process refund
        updates['payoutReleased'] = false;
        
        // Create refund record
        await _firestore.collection('refunds').add({
          'bookingId': bookingId,
          'clientId': booking.clientId,
          'amount': booking.finalAmount,
          'reason': resolution,
          'processedBy': adminId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);

      // Notify both parties
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.clientId,
          type: NotificationType.general,
          title: '✅ Dispute Resolved',
          message: refundToClient ? 'Your dispute has been resolved. Refund processed.' : 'Your dispute has been reviewed.',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: booking.caregiverId,
          type: NotificationType.general,
          title: 'ℹ️ Dispute Resolution',
          message: 'The dispute for booking ${booking.bookingRequestId} has been resolved by admin.',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error resolving dispute: $e');
      return false;
    }
  }

  // ==================== QUERY METHODS ====================

  /// Get bookings by status
  Stream<List<BookingModel>> getBookingsByStatus(String userId, BookingStatus status, {required bool isCaregiver}) {
    final field = isCaregiver ? 'caregiverId' : 'clientId';
    
    return _firestore
        .collection('bookings')
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get pending booking requests for caregiver (Stage 3)
  Stream<List<BookingModel>> getPendingRequests(String caregiverId) {
    return getBookingsByStatus(caregiverId, BookingStatus.pending, isCaregiver: true);
  }

  /// Get bookings awaiting payment (Stage 6)
  Stream<List<BookingModel>> getBookingsAwaitingPayment(String clientId) {
    return getBookingsByStatus(clientId, BookingStatus.pendingPayment, isCaregiver: false);
  }

  /// Get active sessions (Stage 9)
  Stream<List<BookingModel>> getActiveSessions(String userId, {required bool isCaregiver}) {
    return getBookingsByStatus(userId, BookingStatus.inProgress, isCaregiver: isCaregiver);
  }

  /// Get disputed bookings for admin (Stage 13)
  Stream<List<BookingModel>> getDisputedBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: BookingStatus.disputed.name)
        .orderBy('disputedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get all bookings for admin (Stage 13)
  Stream<List<BookingModel>> getAllBookings({BookingStatus? statusFilter}) {
    Query query = _firestore.collection('bookings');

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Get single booking
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

  /// Get bookings for a client
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

  /// Get bookings for a caregiver
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

  // ==================== HELPER METHODS ====================

  /// Check caregiver availability
  Future<bool> _checkCaregiverAvailability(
    String caregiverId,
    DateTime startDate,
    DateTime endDate, {
    String? excludeBookingId,
  }) async {
    try {
      print('🔵 Checking availability for caregiver: $caregiverId');
      print('🔵 Time slot: $startDate to $endDate');
      if (excludeBookingId != null) {
        print('🔵 Excluding booking: $excludeBookingId from conflict check');
      }
      
      // Only check confirmed and in-progress bookings (not pendingPayment as payment may fail)
      final snapshot = await _firestore
          .collection('bookings')
          .where('caregiverId', isEqualTo: caregiverId)
          .where('status', whereIn: ['confirmed', 'inProgress'])
          .get();

      print('🔵 Found ${snapshot.docs.length} confirmed/in-progress bookings');

      for (var doc in snapshot.docs) {
        // Skip the current booking being accepted
        if (excludeBookingId != null && doc.id == excludeBookingId) {
          print('🔵 Skipping current booking ${doc.id}');
          continue;
        }

        final booking = BookingModel.fromMap(doc.id, doc.data());
        
        print('🔵 Checking conflict with booking ${doc.id} (${booking.status.name}): ${booking.startDate} to ${booking.endDate}');
        
        // Check for overlap
        if (startDate.isBefore(booking.endDate) && endDate.isAfter(booking.startDate)) {
          print('❌ Conflict found with booking ${doc.id}');
          return false; // Conflict found
        }
      }

      print('✅ Caregiver is available');
      return true; // Available
    } catch (e, stackTrace) {
      print('❌ Error checking availability: $e');
      print('Stack trace: $stackTrace');
      // On error, allow the booking (availability check failure shouldn't block acceptance)
      return true;
    }
  }

  /// Format date for notifications
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Cancel booking
  Future<bool> cancelBooking(String bookingId, String userId, String reason, {required bool isCaregiver}) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null) return false;

      // Verify user is authorized
      if (isCaregiver && booking.caregiverId != userId) return false;
      if (!isCaregiver && booking.clientId != userId) return false;

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Notify the other party
      final notifyUserId = isCaregiver ? booking.clientId : booking.caregiverId;
      final cancellerName = isCaregiver ? booking.caregiverName : booking.clientName;

      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: notifyUserId,
          type: NotificationType.bookingCancelled,
          title: '❌ Booking Cancelled',
          message: '$cancellerName cancelled the booking. Reason: $reason',
          data: {'bookingId': bookingId},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  /// Get booking statistics
  Future<Map<String, int>> getBookingStatistics(String userId, {required bool isCaregiver}) async {
    try {
      final field = isCaregiver ? 'caregiverId' : 'clientId';
      
      final pending = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: BookingStatus.pending.name)
          .get();

      final confirmed = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .get();

      final inProgress = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: BookingStatus.inProgress.name)
          .get();

      final completed = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .get();

      return {
        'pending': pending.docs.length,
        'confirmed': confirmed.docs.length,
        'inProgress': inProgress.docs.length,
        'completed': completed.docs.length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  /// Get active bookings count for dashboard
  Future<int> getActiveBookingsCount(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('status', whereIn: [
            BookingStatus.pending.name,
            BookingStatus.pendingPayment.name,
            BookingStatus.confirmed.name,
            BookingStatus.inProgress.name,
          ])
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active bookings count: $e');
      return 0;
    }
  }

  /// Get completed bookings count for dashboard
  Future<int> getCompletedBookingsCount(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting completed bookings count: $e');
      return 0;
    }
  }

  /// Get upcoming bookings for dashboard
  Future<List<BookingModel>> getUpcomingBookings(String clientId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('status', whereIn: [
            BookingStatus.confirmed.name,
            BookingStatus.pendingPayment.name,
          ])
          .orderBy('startDate', descending: false)
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .where((booking) => booking.startDate.isAfter(now))
          .toList();
    } catch (e) {
      print('Error getting upcoming bookings: $e');
      return [];
    }
  }
}
