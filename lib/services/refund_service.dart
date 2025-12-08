import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/invoice_model.dart';
import '../models/transaction_model.dart' as txn;
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import 'payment_service.dart';
import 'notification_service.dart';

class RefundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService();

  /// Request a refund
  Future<String?> requestRefund({
    required String transactionId,
    required String bookingId,
    required String requestedBy,
    required String requestedByRole,
    required RefundReason reason,
    required String reasonDescription,
    double? customRefundAmount,
    bool requiresApproval = true,
  }) async {
    try {
      // Get transaction details
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      final transaction = txn.Transaction.fromMap(transactionDoc.data()!, transactionDoc.id);

      if (transaction.status != txn.TransactionStatus.succeeded) {
        throw Exception('Can only refund succeeded transactions');
      }

      // Calculate refund amount
      final refundAmount = customRefundAmount ?? transaction.amount;
      final isPartialRefund = refundAmount < transaction.amount;

      // Calculate refund fee (if applicable)
      final refundFee = _calculateRefundFee(refundAmount, reason);
      final netRefund = refundAmount - refundFee;

      final refund = Refund(
        id: '',
        transactionId: transactionId,
        bookingId: bookingId,
        clientId: transaction.clientId,
        clientName: transaction.clientName,
        caregiverId: transaction.caregiverId,
        caregiverName: transaction.caregiverName,
        requestedBy: requestedBy,
        requestedByRole: requestedByRole,
        originalAmount: transaction.amount,
        refundAmount: refundAmount,
        refundFee: refundFee,
        netRefund: netRefund,
        reason: reason,
        reasonDescription: reasonDescription,
        isPartialRefund: isPartialRefund,
        requiresApproval: requiresApproval,
        requestedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('refunds').add(refund.toMap());

      // Notify admin for approval
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: 'admin',
          type: NotificationType.general,
          title: 'Refund Request',
          message: 'New refund request for \$${refundAmount.toStringAsFixed(2)} - ${reason.name}',
          data: {'refundId': docRef.id, 'bookingId': bookingId},
          createdAt: DateTime.now(),
        ),
      );

      // If doesn't require approval, process immediately
      if (!requiresApproval) {
        await processRefund(refundId: docRef.id);
      }

      return docRef.id;
    } catch (e) {
      print('Error requesting refund: $e');
      return null;
    }
  }

  /// Approve refund (admin)
  Future<bool> approveRefund({
    required String refundId,
    required String approvedBy,
    String? approvalNotes,
  }) async {
    try {
      await _firestore.collection('refunds').doc(refundId).update({
        'isApproved': true,
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalNotes': approvalNotes,
      });

      // Process the refund
      await processRefund(refundId: refundId);

      return true;
    } catch (e) {
      print('Error approving refund: $e');
      return false;
    }
  }

  /// Reject refund (admin)
  Future<bool> rejectRefund({
    required String refundId,
    required String rejectedBy,
    required String rejectionReason,
  }) async {
    try {
      await _firestore.collection('refunds').doc(refundId).update({
        'isApproved': false,
        'approvedBy': rejectedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalNotes': rejectionReason,
        'status': RefundStatus.cancelled.name,
      });

      // Get refund details for notification
      final refundDoc = await _firestore.collection('refunds').doc(refundId).get();
      final refund = Refund.fromMap(refundDoc.data()!, refundDoc.id);

      // Notify requester
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: refund.requestedBy,
          type: NotificationType.general,
          title: 'Refund Rejected',
          message: 'Your refund request has been rejected: $rejectionReason',
          data: {'refundId': refundId},
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error rejecting refund: $e');
      return false;
    }
  }

  /// Process refund
  Future<bool> processRefund({required String refundId}) async {
    try {
      // Get refund details
      final refundDoc = await _firestore.collection('refunds').doc(refundId).get();
      final refund = Refund.fromMap(refundDoc.data()!, refundDoc.id);

      if (refund.requiresApproval && refund.isApproved != true) {
        throw Exception('Refund requires approval');
      }

      // Update status to processing
      await _firestore.collection('refunds').doc(refundId).update({
        'status': RefundStatus.processing.name,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Get transaction details
      final transactionDoc = await _firestore.collection('transactions').doc(refund.transactionId).get();
      final transaction = txn.Transaction.fromMap(transactionDoc.data()!, transactionDoc.id);

      // Process refund through payment gateway
      final gatewayRefund = await _paymentService.createStripeRefund(
        chargeId: transaction.gatewayChargeId!,
        amount: refund.refundAmount,
        reason: refund.reason.name,
      );

      if (gatewayRefund == null) {
        throw Exception('Gateway refund failed');
      }

      // Update refund status
      await _firestore.collection('refunds').doc(refundId).update({
        'status': RefundStatus.completed.name,
        'gatewayRefundId': gatewayRefund['id'],
        'gatewayMetadata': gatewayRefund,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update original transaction
      await _firestore.collection('transactions').doc(refund.transactionId).update({
        'status': refund.isPartialRefund
            ? txn.TransactionStatus.partiallyRefunded.name
            : txn.TransactionStatus.refunded.name,
        'refundedAmount': refund.refundAmount,
        'refundedTransactionId': refundId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Debit caregiver wallet if funds were already transferred
      final wallet = await _paymentService.getWallet(refund.caregiverId);
      if (wallet != null && wallet.availableBalance >= transaction.netAmount) {
        await _paymentService.debitWallet(
          walletId: wallet.id,
          amount: transaction.netAmount,
          transactionId: refundId,
          description: 'Refund for booking ${refund.bookingId}',
        );
      }

      // Send notifications
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: refund.clientId,
          type: NotificationType.general,
          title: 'Refund Processed',
          message: 'Your refund of \$${refund.netRefund.toStringAsFixed(2)} has been processed.',
          data: {'refundId': refundId, 'bookingId': refund.bookingId},
          createdAt: DateTime.now(),
        ),
      );

      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: refund.caregiverId,
          type: NotificationType.general,
          title: 'Refund Issued',
          message: 'A refund of \$${refund.refundAmount.toStringAsFixed(2)} was issued for booking ${refund.bookingId}',
          data: {'refundId': refundId, 'bookingId': refund.bookingId},
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error processing refund: $e');
      
      // Update status to failed
      await _firestore.collection('refunds').doc(refundId).update({
        'status': RefundStatus.failed.name,
        'errorMessage': e.toString(),
      });

      return false;
    }
  }

  /// Calculate refund fee based on reason
  double _calculateRefundFee(double amount, RefundReason reason) {
    switch (reason) {
      case RefundReason.serviceNotProvided:
      case RefundReason.fraudulent:
        return 0.0; // No fee for service failures or fraud
      case RefundReason.clientRequest:
      case RefundReason.poorQuality:
        return amount * 0.05; // 5% fee
      case RefundReason.cancellation:
      case RefundReason.dispute:
      case RefundReason.duplicate:
      case RefundReason.other:
        return amount * 0.03; // 3% fee
    }
  }

  /// Calculate cancellation fee based on policy
  Future<double> calculateCancellationFee({
    required String bookingId,
    required String policyId,
  }) async {
    try {
      // Get booking details
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      final booking = BookingModel.fromMap(bookingDoc.id, bookingDoc.data()!);

      // Get cancellation policy
      final policyDoc = await _firestore.collection('cancellation_policies').doc(policyId).get();
      final policy = CancellationPolicy.fromMap(policyDoc.data()!, policyDoc.id);

      // Calculate fee percentage
      final startTime = booking.startTime != null ? DateTime.parse(booking.startTime!) : DateTime.now();
      final feePercentage = policy.calculateCancellationFee(startTime);

      // Get bill amount
      final billSnapshot = await _firestore
          .collection('bills')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (billSnapshot.docs.isEmpty) {
        return 0.0;
      }

      final billData = billSnapshot.docs.first.data();
      final billAmount = (billData['finalCost'] ?? 0).toDouble();

      return billAmount * (feePercentage / 100);
    } catch (e) {
      print('Error calculating cancellation fee: $e');
      return 0.0;
    }
  }

  /// Process cancellation with fee
  Future<String?> processCancellationWithFee({
    required String bookingId,
    required String policyId,
    required String cancelledBy,
    required String cancellationReason,
  }) async {
    try {
      final cancellationFee = await calculateCancellationFee(
        bookingId: bookingId,
        policyId: policyId,
      );

      if (cancellationFee == 0.0) {
        return null; // No fee to charge
      }

      // Get booking details
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      final booking = BookingModel.fromMap(bookingDoc.id, bookingDoc.data()!);

      // Create cancellation fee transaction
      final transactionId = await _paymentService.createTransaction(
        type: txn.TransactionType.cancellationFee,
        amount: cancellationFee,
        bookingId: bookingId,
        clientId: booking.clientId,
        clientName: booking.clientName,
        caregiverId: booking.caregiverId,
        caregiverName: booking.caregiverName,
        metadata: {
          'policy_id': policyId,
          'cancelled_by': cancelledBy,
          'cancellation_reason': cancellationReason,
        },
        description: 'Cancellation fee for booking $bookingId',
      );

      // Credit caregiver with cancellation compensation
      final wallet = await _paymentService.getWallet(booking.caregiverId);
      if (wallet != null) {
        final caregiverCompensation = cancellationFee * 0.7; // 70% to caregiver, 30% platform keeps
        await _paymentService.creditWallet(
          walletId: wallet.id,
          amount: caregiverCompensation,
          transactionId: transactionId!,
          description: 'Cancellation compensation',
        );
      }

      return transactionId;
    } catch (e) {
      print('Error processing cancellation fee: $e');
      return null;
    }
  }

  /// Get pending refund requests (admin)
  Stream<List<Refund>> getPendingRefunds() {
    return _firestore
        .collection('refunds')
        .where('status', isEqualTo: RefundStatus.pending.name)
        .where('requiresApproval', isEqualTo: true)
        .where('isApproved', isNull: true)
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Refund.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get refunds for a booking
  Stream<List<Refund>> getBookingRefunds(String bookingId) {
    return _firestore
        .collection('refunds')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Refund.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get user refunds
  Stream<List<Refund>> getUserRefunds({
    required String userId,
    required String userRole,
  }) {
    final field = userRole == 'client' ? 'clientId' : 'caregiverId';
    return _firestore
        .collection('refunds')
        .where(field, isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Refund.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get default cancellation policy
  Future<CancellationPolicy?> getDefaultCancellationPolicy() async {
    try {
      final snapshot = await _firestore
          .collection('cancellation_policies')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Create default policy if none exists
        return await _createDefaultCancellationPolicy();
      }

      return CancellationPolicy.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      print('Error getting cancellation policy: $e');
      return null;
    }
  }

  /// Create default cancellation policy
  Future<CancellationPolicy> _createDefaultCancellationPolicy() async {
    final policy = CancellationPolicy(
      id: '',
      name: 'Standard Cancellation Policy',
      description: 'Default cancellation policy for all bookings',
      isActive: true,
      feeRules: [
        CancellationFeeRule(hoursBeforeBooking: 2, feePercentage: 100.0), // <2 hours: 100%
        CancellationFeeRule(hoursBeforeBooking: 12, feePercentage: 50.0), // <12 hours: 50%
        CancellationFeeRule(hoursBeforeBooking: 24, feePercentage: 25.0), // <24 hours: 25%
        CancellationFeeRule(hoursBeforeBooking: 48, feePercentage: 10.0), // <48 hours: 10%
      ],
      defaultFeePercentage: 0.0, // >48 hours: no fee
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('cancellation_policies').add(policy.toMap());
    return CancellationPolicy.fromMap(policy.toMap(), docRef.id);
  }
}
