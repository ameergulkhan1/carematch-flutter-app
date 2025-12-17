import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transaction_model.dart' as txn;
import '../models/bill_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TODO: Store these securely in environment variables or Firebase Remote Config
  static const String _stripeSecretKey = 'sk_test_YOUR_STRIPE_KEY';
  // Reserved for future payment provider integration
  // static const String _paystackSecretKey = 'sk_test_YOUR_PAYSTACK_KEY';
  // static const String _fawryMerchantCode = 'YOUR_FAWRY_MERCHANT_CODE';

  // Platform fee configuration
  static const double _platformFeePercentage = 15.0; // 15% platform fee
  static const double _stripeProcessingFeePercentage = 2.9; // 2.9% + $0.30
  static const double _stripeProcessingFeeFixed = 0.30;

  /// Create a payment intent with Stripe
  Future<Map<String, dynamic>?> createStripePaymentIntent({
    required double amount,
    required String currency,
    required String clientId,
    required String bookingId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(), // Convert to cents
          'currency': currency.toLowerCase(),
          'customer': clientId, // Use Stripe customer ID
          'metadata[booking_id]': bookingId,
          'metadata[client_id]': clientId,
          if (metadata != null)
            ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
          'capture_method': 'manual', // Manual capture for approval flow
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Stripe API error: ${response.body}');
      }
    } catch (e) {
      print('Error creating Stripe payment intent: $e');
      return null;
    }
  }

  /// Capture a Stripe payment
  Future<bool> captureStripePayment({
    required String paymentIntentId,
    double? amountToCapture,
  }) async {
    try {
      final body = <String, String>{};
      if (amountToCapture != null) {
        body['amount_to_capture'] = (amountToCapture * 100).toInt().toString();
      }

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId/capture'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error capturing Stripe payment: $e');
      return false;
    }
  }

  /// Create a Stripe refund
  Future<Map<String, dynamic>?> createStripeRefund({
    required String chargeId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/refunds'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'charge': chargeId,
          'amount': (amount * 100).toInt().toString(),
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Stripe refund error: ${response.body}');
      }
    } catch (e) {
      print('Error creating Stripe refund: $e');
      return null;
    }
  }

  /// Create transaction record
  Future<String?> createTransaction({
    required txn.TransactionType type,
    required double amount,
    required String bookingId,
    required String clientId,
    required String clientName,
    required String caregiverId,
    required String caregiverName,
    String? billId,
    String? invoiceId,
    txn.PaymentGateway gateway = txn.PaymentGateway.stripe,
    txn.PaymentMethod paymentMethod = txn.PaymentMethod.card,
    String? gatewayTransactionId,
    String? gatewayPaymentIntentId,
    String? gatewayChargeId,
    Map<String, dynamic>? metadata,
    String? description,
  }) async {
    try {
      // Calculate fees
      final platformFee = amount * (_platformFeePercentage / 100);
      final processingFee = (amount * (_stripeProcessingFeePercentage / 100)) + 
          _stripeProcessingFeeFixed;
      final netAmount = amount - platformFee - processingFee;

      final transaction = txn.Transaction(
        id: '',
        type: type,
        status: txn.TransactionStatus.pending,
        paymentMethod: paymentMethod,
        gateway: gateway,
        amount: amount,
        platformFee: platformFee,
        processingFee: processingFee,
        netAmount: netAmount,
        bookingId: bookingId,
        billId: billId,
        invoiceId: invoiceId,
        clientId: clientId,
        clientName: clientName,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        gatewayTransactionId: gatewayTransactionId,
        gatewayPaymentIntentId: gatewayPaymentIntentId,
        gatewayChargeId: gatewayChargeId,
        gatewayMetadata: metadata,
        description: description ?? 'Payment for booking $bookingId',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('transactions').add(transaction.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }

  /// Update transaction status
  Future<bool> updateTransactionStatus({
    required String transactionId,
    required txn.TransactionStatus status,
    String? errorMessage,
    String? errorCode,
    DateTime? processedAt,
    DateTime? settledAt,
  }) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (errorCode != null) 'errorCode': errorCode,
        if (processedAt != null) 'processedAt': Timestamp.fromDate(processedAt),
        if (settledAt != null) 'settledAt': Timestamp.fromDate(settledAt),
      });
      return true;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  /// Get transactions for a booking
  Stream<List<txn.Transaction>> getBookingTransactions(String bookingId) {
    return _firestore
        .collection('transactions')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => txn.Transaction.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get transactions for a user
  Stream<List<txn.Transaction>> getUserTransactions({
    required String userId,
    required String userRole, // 'client' or 'caregiver'
  }) {
    final field = userRole == 'client' ? 'clientId' : 'caregiverId';
    return _firestore
        .collection('transactions')
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => txn.Transaction.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Process charge and capture flow
  Future<Map<String, dynamic>> processPayment({
    required Bill bill,
    required String clientId,
    required txn.PaymentMethod paymentMethod,
    txn.PaymentGateway gateway = txn.PaymentGateway.stripe,
  }) async {
    try {
      // Step 1: Create payment intent (authorization)
      final paymentIntent = await createStripePaymentIntent(
        amount: bill.totalAmount,
        currency: 'usd',
        clientId: clientId,
        bookingId: bill.bookingId,
        metadata: {
          'bill_id': bill.id,
          'caregiver_id': bill.caregiverId,
        },
      );

      if (paymentIntent == null) {
        return {
          'success': false,
          'error': 'Failed to create payment intent',
        };
      }

      // Step 2: Create transaction record
      final transactionId = await createTransaction(
        type: txn.TransactionType.charge,
        amount: bill.totalAmount,
        bookingId: bill.bookingId,
        clientId: clientId,
        clientName: bill.clientName,
        caregiverId: bill.caregiverId,
        caregiverName: bill.caregiverName,
        billId: bill.id,
        gateway: gateway,
        paymentMethod: paymentMethod,
        gatewayPaymentIntentId: paymentIntent['id'],
        metadata: paymentIntent,
        description: 'Payment for booking ${bill.bookingId}',
      );

      return {
        'success': true,
        'transactionId': transactionId,
        'paymentIntentId': paymentIntent['id'],
        'clientSecret': paymentIntent['client_secret'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Capture payment after client approval
  Future<bool> capturePaymentAfterApproval({
    required String transactionId,
    required String paymentIntentId,
  }) async {
    try {
      // Capture the payment
      final captured = await captureStripePayment(
        paymentIntentId: paymentIntentId,
      );

      if (captured) {
        // Update transaction status
        await updateTransactionStatus(
          transactionId: transactionId,
          status: txn.TransactionStatus.succeeded,
          processedAt: DateTime.now(),
          settledAt: DateTime.now(),
        );

        return true;
      }

      return false;
    } catch (e) {
      print('Error capturing payment: $e');
      await updateTransactionStatus(
        transactionId: transactionId,
        status: txn.TransactionStatus.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Create or get wallet for user
  Future<txn.Wallet?> getOrCreateWallet({
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    try {
      // Check if wallet exists
      final existing = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return txn.Wallet.fromMap(existing.docs.first.data(), existing.docs.first.id);
      }

      // Create new wallet
      final wallet = txn.Wallet(
        id: '',
        userId: userId,
        userName: userName,
        userRole: userRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('wallets').add(wallet.toMap());
      return txn.Wallet.fromMap(wallet.toMap(), docRef.id);
    } catch (e) {
      print('Error getting/creating wallet: $e');
      return null;
    }
  }

  /// Credit wallet (add funds)
  Future<bool> creditWallet({
    required String walletId,
    required double amount,
    required String transactionId,
    String description = 'Wallet credit',
  }) async {
    try {
      await _firestore.collection('wallets').doc(walletId).update({
        'availableBalance': FieldValue.increment(amount),
        'totalEarnings': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create wallet transaction record
      await _firestore.collection('wallet_transactions').add({
        'walletId': walletId,
        'type': 'credit',
        'amount': amount,
        'relatedTransactionId': transactionId,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error crediting wallet: $e');
      return false;
    }
  }

  /// Debit wallet (withdraw funds)
  Future<bool> debitWallet({
    required String walletId,
    required double amount,
    required String transactionId,
    String description = 'Wallet debit',
  }) async {
    try {
      final wallet = await _firestore.collection('wallets').doc(walletId).get();
      final walletData = txn.Wallet.fromMap(wallet.data()!, wallet.id);

      if (walletData.availableBalance < amount) {
        throw Exception('Insufficient balance');
      }

      await _firestore.collection('wallets').doc(walletId).update({
        'availableBalance': FieldValue.increment(-amount),
        'totalWithdrawals': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create wallet transaction record
      await _firestore.collection('wallet_transactions').add({
        'walletId': walletId,
        'type': 'debit',
        'amount': amount,
        'relatedTransactionId': transactionId,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error debiting wallet: $e');
      return false;
    }
  }

  /// Request payout for caregiver
  Future<String?> requestPayout({
    required String caregiverId,
    required String caregiverName,
    required double amount,
    String? bankName,
    String? accountNumber,
    String? accountHolderName,
  }) async {
    try {
      final wallet = await getOrCreateWallet(
        userId: caregiverId,
        userName: caregiverName,
        userRole: 'caregiver',
      );

      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      if (wallet.availableBalance < amount) {
        throw Exception('Insufficient balance');
      }

      if (amount < wallet.minWithdrawalAmount) {
        throw Exception('Amount below minimum withdrawal limit');
      }

      // Calculate payout fee (e.g., 2%)
      final payoutFee = amount * 0.02;
      final netAmount = amount - payoutFee;

      final payout = txn.Payout(
        id: '',
        walletId: wallet.id,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        amount: amount,
        fee: payoutFee,
        netAmount: netAmount,
        gateway: txn.PaymentGateway.stripe,
        bankName: bankName ?? wallet.bankName ?? '',
        accountNumber: accountNumber ?? wallet.accountNumber ?? '',
        accountHolderName: accountHolderName ?? wallet.accountHolderName ?? '',
        description: 'Payout request',
        requestedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('payouts').add(payout.toMap());

      // Move funds from available to pending
      await _firestore.collection('wallets').doc(wallet.id).update({
        'availableBalance': FieldValue.increment(-amount),
        'pendingBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error requesting payout: $e');
      return null;
    }
  }

  /// Get wallet by user ID
  Future<txn.Wallet?> getWallet(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return txn.Wallet.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      print('Error getting wallet: $e');
      return null;
    }
  }

  /// Get pending payouts
  Stream<List<txn.Payout>> getPendingPayouts() {
    return _firestore
        .collection('payouts')
        .where('status', isEqualTo: txn.PayoutStatus.pending.name)
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => txn.Payout.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get caregiver payouts
  Stream<List<txn.Payout>> getCaregiverPayouts(String caregiverId) {
    return _firestore
        .collection('payouts')
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('requestedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => txn.Payout.fromMap(doc.data(), doc.id))
            .toList());
  }
}
