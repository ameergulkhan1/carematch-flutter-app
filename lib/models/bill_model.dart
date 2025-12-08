import 'package:cloud_firestore/cloud_firestore.dart';

enum BillStatus {
  pending,
  approved,
  paid,
  disputed,
  cancelled,
  overdue,
}

class Bill {
  final String id;
  final String bookingId;
  final String caregiverId;
  final String caregiverName;
  final String clientId;
  final String clientName;

  // Cost breakdown
  final double hourlyRate;
  final double durationHours;
  final double baseCost; // hourlyRate * durationHours
  final double additionalCharges; // Extra fees, overtime, etc.
  final double subtotal; // baseCost + additionalCharges
  final double platformFee; // Platform's commission
  final double totalAmount; // Final amount client pays

  // Status tracking
  final BillStatus status;
  final String? disputeReason;
  final String? disputeDetails;

  // Timestamps
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;
  final DateTime? disputedAt;

  // References
  final String? transactionId;
  final String? invoiceId;

  Bill({
    required this.id,
    required this.bookingId,
    required this.caregiverId,
    required this.caregiverName,
    required this.clientId,
    required this.clientName,
    required this.hourlyRate,
    required this.durationHours,
    required this.baseCost,
    this.additionalCharges = 0.0,
    required this.subtotal,
    required this.platformFee,
    required this.totalAmount,
    this.status = BillStatus.pending,
    this.disputeReason,
    this.disputeDetails,
    required this.createdAt,
    this.approvedAt,
    this.paidAt,
    this.disputedAt,
    this.transactionId,
    this.invoiceId,
  });

  /// Convert Bill to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'clientId': clientId,
      'clientName': clientName,
      'hourlyRate': hourlyRate,
      'durationHours': durationHours,
      'baseCost': baseCost,
      'additionalCharges': additionalCharges,
      'subtotal': subtotal,
      'platformFee': platformFee,
      'totalAmount': totalAmount,
      'status': status.name,
      'disputeReason': disputeReason,
      'disputeDetails': disputeDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'disputedAt': disputedAt != null ? Timestamp.fromDate(disputedAt!) : null,
      'transactionId': transactionId,
      'invoiceId': invoiceId,
    };
  }

  /// Create Bill from Firestore map
  factory Bill.fromMap(Map<String, dynamic> map, String id) {
    return Bill(
      id: id,
      bookingId: map['bookingId'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      durationHours: (map['durationHours'] ?? 0.0).toDouble(),
      baseCost: (map['baseCost'] ?? 0.0).toDouble(),
      additionalCharges: (map['additionalCharges'] ?? 0.0).toDouble(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      platformFee: (map['platformFee'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: _parseStatus(map['status']),
      disputeReason: map['disputeReason'],
      disputeDetails: map['disputeDetails'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      disputedAt: (map['disputedAt'] as Timestamp?)?.toDate(),
      transactionId: map['transactionId'],
      invoiceId: map['invoiceId'],
    );
  }

  /// Parse status string to BillStatus enum
  static BillStatus _parseStatus(String? status) {
    if (status == null) return BillStatus.pending;
    try {
      return BillStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => BillStatus.pending,
      );
    } catch (e) {
      return BillStatus.pending;
    }
  }

  /// Create a copy with updated fields
  Bill copyWith({
    String? id,
    String? bookingId,
    String? caregiverId,
    String? caregiverName,
    String? clientId,
    String? clientName,
    double? hourlyRate,
    double? durationHours,
    double? baseCost,
    double? additionalCharges,
    double? subtotal,
    double? platformFee,
    double? totalAmount,
    BillStatus? status,
    String? disputeReason,
    String? disputeDetails,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? paidAt,
    DateTime? disputedAt,
    String? transactionId,
    String? invoiceId,
  }) {
    return Bill(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      caregiverId: caregiverId ?? this.caregiverId,
      caregiverName: caregiverName ?? this.caregiverName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      durationHours: durationHours ?? this.durationHours,
      baseCost: baseCost ?? this.baseCost,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      subtotal: subtotal ?? this.subtotal,
      platformFee: platformFee ?? this.platformFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeDetails: disputeDetails ?? this.disputeDetails,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      paidAt: paidAt ?? this.paidAt,
      disputedAt: disputedAt ?? this.disputedAt,
      transactionId: transactionId ?? this.transactionId,
      invoiceId: invoiceId ?? this.invoiceId,
    );
  }

  @override
  String toString() {
    return 'Bill(id: $id, bookingId: $bookingId, totalAmount: $totalAmount, status: ${status.name})';
  }
}
