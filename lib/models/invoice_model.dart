import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus {
  draft,
  sent,
  paid,
  partiallyPaid,
  overdue,
  cancelled,
  refunded,
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final InvoiceStatus status;

  // Related entities
  final String bookingId;
  final String billId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String? clientPhone;
  final String caregiverId;
  final String caregiverName;

  // Amount breakdown
  final double subtotal;
  final double platformFee;
  final double processingFee;
  final double discount;
  final double tax;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final String currency;

  // Line items
  final List<InvoiceLineItem> lineItems;

  // Payment details
  final List<String> transactionIds;
  final DateTime? paidAt;
  final PaymentMethod? paymentMethod;

  // PDF & delivery
  final String? pdfUrl;
  final bool emailSent;
  final DateTime? emailSentAt;
  final String? emailRecipient;

  // Dates
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Metadata
  final String? notes;
  final Map<String, dynamic>? metadata;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.bookingId,
    required this.billId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    this.clientPhone,
    required this.caregiverId,
    required this.caregiverName,
    required this.subtotal,
    required this.platformFee,
    required this.processingFee,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.balanceDue,
    this.currency = 'USD',
    this.lineItems = const [],
    this.transactionIds = const [],
    this.paidAt,
    this.paymentMethod,
    this.pdfUrl,
    this.emailSent = false,
    this.emailSentAt,
    this.emailRecipient,
    required this.issueDate,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.metadata,
  });

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      bookingId: map['bookingId'] ?? '',
      billId: map['billId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      clientPhone: map['clientPhone'],
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      processingFee: (map['processingFee'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      balanceDue: (map['balanceDue'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      lineItems: (map['lineItems'] as List<dynamic>?)
              ?.map((item) => InvoiceLineItem.fromMap(item))
              .toList() ??
          [],
      transactionIds: List<String>.from(map['transactionIds'] ?? []),
      paidAt: map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere((e) => e.name == map['paymentMethod'])
          : null,
      pdfUrl: map['pdfUrl'],
      emailSent: map['emailSent'] ?? false,
      emailSentAt: map['emailSentAt'] != null
          ? (map['emailSentAt'] as Timestamp).toDate()
          : null,
      emailRecipient: map['emailRecipient'],
      issueDate: (map['issueDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'status': status.name,
      'bookingId': bookingId,
      'billId': billId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'subtotal': subtotal,
      'platformFee': platformFee,
      'processingFee': processingFee,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceDue': balanceDue,
      'currency': currency,
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'transactionIds': transactionIds,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paymentMethod': paymentMethod?.name,
      'pdfUrl': pdfUrl,
      'emailSent': emailSent,
      'emailSentAt': emailSentAt != null ? Timestamp.fromDate(emailSentAt!) : null,
      'emailRecipient': emailRecipient,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'metadata': metadata,
    };
  }
}

class InvoiceLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'amount': amount,
    };
  }
}

enum PaymentMethod {
  card,
  wallet,
  bankTransfer,
  cash,
  mobileMoney,
}

enum RefundStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

enum RefundReason {
  clientRequest,
  serviceNotProvided,
  poorQuality,
  cancellation,
  dispute,
  duplicate,
  fraudulent,
  other,
}

class Refund {
  final String id;
  final String transactionId;
  final String bookingId;
  final String? invoiceId;

  // Parties
  final String clientId;
  final String clientName;
  final String caregiverId;
  final String caregiverName;
  final String requestedBy;
  final String requestedByRole;

  // Amount details
  final double originalAmount;
  final double refundAmount;
  final double refundFee;
  final double netRefund;
  final String currency;

  // Refund details
  final RefundReason reason;
  final String reasonDescription;
  final RefundStatus status;
  final bool isPartialRefund;

  // Gateway details
  final String? gatewayRefundId;
  final Map<String, dynamic>? gatewayMetadata;

  // Approval workflow
  final bool requiresApproval;
  final bool? isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? approvalNotes;

  // Timestamps
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;

  // Error handling
  final String? errorMessage;
  final String? errorCode;

  Refund({
    required this.id,
    required this.transactionId,
    required this.bookingId,
    this.invoiceId,
    required this.clientId,
    required this.clientName,
    required this.caregiverId,
    required this.caregiverName,
    required this.requestedBy,
    required this.requestedByRole,
    required this.originalAmount,
    required this.refundAmount,
    this.refundFee = 0.0,
    required this.netRefund,
    this.currency = 'USD',
    required this.reason,
    required this.reasonDescription,
    this.status = RefundStatus.pending,
    this.isPartialRefund = false,
    this.gatewayRefundId,
    this.gatewayMetadata,
    this.requiresApproval = true,
    this.isApproved,
    this.approvedBy,
    this.approvedAt,
    this.approvalNotes,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
    this.errorMessage,
    this.errorCode,
  });

  factory Refund.fromMap(Map<String, dynamic> map, String id) {
    return Refund(
      id: id,
      transactionId: map['transactionId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      invoiceId: map['invoiceId'],
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      requestedByRole: map['requestedByRole'] ?? '',
      originalAmount: (map['originalAmount'] ?? 0).toDouble(),
      refundAmount: (map['refundAmount'] ?? 0).toDouble(),
      refundFee: (map['refundFee'] ?? 0).toDouble(),
      netRefund: (map['netRefund'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      reason: RefundReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => RefundReason.other,
      ),
      reasonDescription: map['reasonDescription'] ?? '',
      status: RefundStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RefundStatus.pending,
      ),
      isPartialRefund: map['isPartialRefund'] ?? false,
      gatewayRefundId: map['gatewayRefundId'],
      gatewayMetadata: map['gatewayMetadata'],
      requiresApproval: map['requiresApproval'] ?? true,
      isApproved: map['isApproved'],
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      approvalNotes: map['approvalNotes'],
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      errorMessage: map['errorMessage'],
      errorCode: map['errorCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'bookingId': bookingId,
      'invoiceId': invoiceId,
      'clientId': clientId,
      'clientName': clientName,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'requestedBy': requestedBy,
      'requestedByRole': requestedByRole,
      'originalAmount': originalAmount,
      'refundAmount': refundAmount,
      'refundFee': refundFee,
      'netRefund': netRefund,
      'currency': currency,
      'reason': reason.name,
      'reasonDescription': reasonDescription,
      'status': status.name,
      'isPartialRefund': isPartialRefund,
      'gatewayRefundId': gatewayRefundId,
      'gatewayMetadata': gatewayMetadata,
      'requiresApproval': requiresApproval,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvalNotes': approvalNotes,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
    };
  }
}

class CancellationPolicy {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  // Time-based fee structure (hours before booking)
  final List<CancellationFeeRule> feeRules;

  // Default rule if no time rules match
  final double defaultFeePercentage;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  CancellationPolicy({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    this.feeRules = const [],
    this.defaultFeePercentage = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CancellationPolicy.fromMap(Map<String, dynamic> map, String id) {
    return CancellationPolicy(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      feeRules: (map['feeRules'] as List<dynamic>?)
              ?.map((rule) => CancellationFeeRule.fromMap(rule))
              .toList() ??
          [],
      defaultFeePercentage: (map['defaultFeePercentage'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'feeRules': feeRules.map((rule) => rule.toMap()).toList(),
      'defaultFeePercentage': defaultFeePercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  double calculateCancellationFee(DateTime bookingStartTime) {
    final hoursUntilBooking = bookingStartTime.difference(DateTime.now()).inHours;

    for (final rule in feeRules) {
      if (hoursUntilBooking <= rule.hoursBeforeBooking) {
        return rule.feePercentage;
      }
    }

    return defaultFeePercentage;
  }
}

class CancellationFeeRule {
  final int hoursBeforeBooking;
  final double feePercentage;

  CancellationFeeRule({
    required this.hoursBeforeBooking,
    required this.feePercentage,
  });

  factory CancellationFeeRule.fromMap(Map<String, dynamic> map) {
    return CancellationFeeRule(
      hoursBeforeBooking: map['hoursBeforeBooking'] ?? 0,
      feePercentage: (map['feePercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hoursBeforeBooking': hoursBeforeBooking,
      'feePercentage': feePercentage,
    };
  }
}
