import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  charge,
  capture,
  refund,
  payout,
  walletCredit,
  walletDebit,
  adjustment,
  cancellationFee,
}

enum TransactionStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

enum PaymentMethod {
  card,
  wallet,
  bankTransfer,
  cash,
  mobileMoney,
}

enum PaymentGateway {
  stripe,
  paystack,
  fawry,
  manual,
}

class Transaction {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final PaymentGateway gateway;

  // Amount details
  final double amount;
  final double platformFee;
  final double processingFee;
  final double netAmount;
  final String currency;

  // Related entities
  final String bookingId;
  final String? billId;
  final String? invoiceId;
  final String clientId;
  final String clientName;
  final String caregiverId;
  final String caregiverName;

  // Payment gateway details
  final String? gatewayTransactionId;
  final String? gatewayPaymentIntentId;
  final String? gatewayChargeId;
  final Map<String, dynamic>? gatewayMetadata;

  // Refund details
  final String? refundReason;
  final String? refundedTransactionId;
  final double? refundedAmount;

  // Cancellation details
  final String? cancellationPolicyId;
  final double? cancellationFeePercentage;

  // Metadata
  final String description;
  final Map<String, dynamic>? metadata;
  final String? notes;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
  final DateTime? settledAt;

  // Error handling
  final String? errorMessage;
  final String? errorCode;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.paymentMethod,
    required this.gateway,
    required this.amount,
    required this.platformFee,
    required this.processingFee,
    required this.netAmount,
    this.currency = 'USD',
    required this.bookingId,
    this.billId,
    this.invoiceId,
    required this.clientId,
    required this.clientName,
    required this.caregiverId,
    required this.caregiverName,
    this.gatewayTransactionId,
    this.gatewayPaymentIntentId,
    this.gatewayChargeId,
    this.gatewayMetadata,
    this.refundReason,
    this.refundedTransactionId,
    this.refundedAmount,
    this.cancellationPolicyId,
    this.cancellationFeePercentage,
    required this.description,
    this.metadata,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
    this.settledAt,
    this.errorMessage,
    this.errorCode,
  });

  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.charge,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.card,
      ),
      gateway: PaymentGateway.values.firstWhere(
        (e) => e.name == map['gateway'],
        orElse: () => PaymentGateway.stripe,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      processingFee: (map['processingFee'] ?? 0).toDouble(),
      netAmount: (map['netAmount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      bookingId: map['bookingId'] ?? '',
      billId: map['billId'],
      invoiceId: map['invoiceId'],
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      gatewayTransactionId: map['gatewayTransactionId'],
      gatewayPaymentIntentId: map['gatewayPaymentIntentId'],
      gatewayChargeId: map['gatewayChargeId'],
      gatewayMetadata: map['gatewayMetadata'],
      refundReason: map['refundReason'],
      refundedTransactionId: map['refundedTransactionId'],
      refundedAmount: map['refundedAmount']?.toDouble(),
      cancellationPolicyId: map['cancellationPolicyId'],
      cancellationFeePercentage: map['cancellationFeePercentage']?.toDouble(),
      description: map['description'] ?? '',
      metadata: map['metadata'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      settledAt: map['settledAt'] != null
          ? (map['settledAt'] as Timestamp).toDate()
          : null,
      errorMessage: map['errorMessage'],
      errorCode: map['errorCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'gateway': gateway.name,
      'amount': amount,
      'platformFee': platformFee,
      'processingFee': processingFee,
      'netAmount': netAmount,
      'currency': currency,
      'bookingId': bookingId,
      'billId': billId,
      'invoiceId': invoiceId,
      'clientId': clientId,
      'clientName': clientName,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'gatewayTransactionId': gatewayTransactionId,
      'gatewayPaymentIntentId': gatewayPaymentIntentId,
      'gatewayChargeId': gatewayChargeId,
      'gatewayMetadata': gatewayMetadata,
      'refundReason': refundReason,
      'refundedTransactionId': refundedTransactionId,
      'refundedAmount': refundedAmount,
      'cancellationPolicyId': cancellationPolicyId,
      'cancellationFeePercentage': cancellationFeePercentage,
      'description': description,
      'metadata': metadata,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'settledAt': settledAt != null ? Timestamp.fromDate(settledAt!) : null,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
    };
  }
}

class Wallet {
  final String id;
  final String userId;
  final String userName;
  final String userRole; // 'client' or 'caregiver'

  // Balance
  final double availableBalance;
  final double pendingBalance;
  final double totalEarnings;
  final double totalWithdrawals;
  final String currency;

  // Limits
  final double minWithdrawalAmount;
  final double maxWithdrawalAmount;

  // Status
  final bool isActive;
  final bool isVerified;
  final String? suspensionReason;

  // Bank account for payouts (caregiver only)
  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? routingNumber;
  final String? swiftCode;

  // Gateway IDs
  final String? stripeAccountId;
  final String? paystackRecipientCode;
  final String? fawryMerchantId;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastPayoutAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.totalEarnings = 0.0,
    this.totalWithdrawals = 0.0,
    this.currency = 'USD',
    this.minWithdrawalAmount = 10.0,
    this.maxWithdrawalAmount = 10000.0,
    this.isActive = true,
    this.isVerified = false,
    this.suspensionReason,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.routingNumber,
    this.swiftCode,
    this.stripeAccountId,
    this.paystackRecipientCode,
    this.fawryMerchantId,
    required this.createdAt,
    required this.updatedAt,
    this.lastPayoutAt,
  });

  factory Wallet.fromMap(Map<String, dynamic> map, String id) {
    return Wallet(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      availableBalance: (map['availableBalance'] ?? 0).toDouble(),
      pendingBalance: (map['pendingBalance'] ?? 0).toDouble(),
      totalEarnings: (map['totalEarnings'] ?? 0).toDouble(),
      totalWithdrawals: (map['totalWithdrawals'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      minWithdrawalAmount: (map['minWithdrawalAmount'] ?? 10.0).toDouble(),
      maxWithdrawalAmount: (map['maxWithdrawalAmount'] ?? 10000.0).toDouble(),
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      suspensionReason: map['suspensionReason'],
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      accountHolderName: map['accountHolderName'],
      routingNumber: map['routingNumber'],
      swiftCode: map['swiftCode'],
      stripeAccountId: map['stripeAccountId'],
      paystackRecipientCode: map['paystackRecipientCode'],
      fawryMerchantId: map['fawryMerchantId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastPayoutAt: map['lastPayoutAt'] != null
          ? (map['lastPayoutAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'totalEarnings': totalEarnings,
      'totalWithdrawals': totalWithdrawals,
      'currency': currency,
      'minWithdrawalAmount': minWithdrawalAmount,
      'maxWithdrawalAmount': maxWithdrawalAmount,
      'isActive': isActive,
      'isVerified': isVerified,
      'suspensionReason': suspensionReason,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'routingNumber': routingNumber,
      'swiftCode': swiftCode,
      'stripeAccountId': stripeAccountId,
      'paystackRecipientCode': paystackRecipientCode,
      'fawryMerchantId': fawryMerchantId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastPayoutAt': lastPayoutAt != null ? Timestamp.fromDate(lastPayoutAt!) : null,
    };
  }
}

enum PayoutStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class Payout {
  final String id;
  final String walletId;
  final String caregiverId;
  final String caregiverName;

  // Amount details
  final double amount;
  final double fee;
  final double netAmount;
  final String currency;

  // Gateway details
  final PaymentGateway gateway;
  final String? gatewayPayoutId;
  final String? gatewayTransferId;
  final Map<String, dynamic>? gatewayMetadata;

  // Bank details
  final String bankName;
  final String accountNumber;
  final String accountHolderName;

  // Status
  final PayoutStatus status;
  final String? failureReason;
  final String? failureCode;

  // Metadata
  final String description;
  final List<String> includedTransactionIds;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final String? notes;

  Payout({
    required this.id,
    required this.walletId,
    required this.caregiverId,
    required this.caregiverName,
    required this.amount,
    required this.fee,
    required this.netAmount,
    this.currency = 'USD',
    required this.gateway,
    this.gatewayPayoutId,
    this.gatewayTransferId,
    this.gatewayMetadata,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.status = PayoutStatus.pending,
    this.failureReason,
    this.failureCode,
    required this.description,
    this.includedTransactionIds = const [],
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.notes,
  });

  factory Payout.fromMap(Map<String, dynamic> map, String id) {
    return Payout(
      id: id,
      walletId: map['walletId'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      fee: (map['fee'] ?? 0).toDouble(),
      netAmount: (map['netAmount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      gateway: PaymentGateway.values.firstWhere(
        (e) => e.name == map['gateway'],
        orElse: () => PaymentGateway.stripe,
      ),
      gatewayPayoutId: map['gatewayPayoutId'],
      gatewayTransferId: map['gatewayTransferId'],
      gatewayMetadata: map['gatewayMetadata'],
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountHolderName: map['accountHolderName'] ?? '',
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PayoutStatus.pending,
      ),
      failureReason: map['failureReason'],
      failureCode: map['failureCode'],
      description: map['description'] ?? '',
      includedTransactionIds: List<String>.from(map['includedTransactionIds'] ?? []),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walletId': walletId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'amount': amount,
      'fee': fee,
      'netAmount': netAmount,
      'currency': currency,
      'gateway': gateway.name,
      'gatewayPayoutId': gatewayPayoutId,
      'gatewayTransferId': gatewayTransferId,
      'gatewayMetadata': gatewayMetadata,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'status': status.name,
      'failureReason': failureReason,
      'failureCode': failureCode,
      'description': description,
      'includedTransactionIds': includedTransactionIds,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
    };
  }
}
