import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
}

enum BookingType {
  oneTime,
  recurring,
}

class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String caregiverId;
  final String caregiverName;
  final String? caregiverImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final BookingType bookingType;
  final List<String> services;
  final String? specialRequirements;
  final double hourlyRate;
  final int totalHours;
  final double totalAmount;
  final double platformFee;
  final double finalAmount;
  final BookingStatus status;
  final String? cancellationReason;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final bool isPaid;
  final String? paymentId;
  final Map<String, dynamic>? clientAddress;
  final String? clientPhone;
  final String? caregiverPhone;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.caregiverId,
    required this.caregiverName,
    this.caregiverImageUrl,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.bookingType,
    required this.services,
    this.specialRequirements,
    required this.hourlyRate,
    required this.totalHours,
    required this.totalAmount,
    required this.platformFee,
    required this.finalAmount,
    required this.status,
    this.cancellationReason,
    this.rejectionReason,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.isPaid = false,
    this.paymentId,
    this.clientAddress,
    this.clientPhone,
    this.caregiverPhone,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'caregiverImageUrl': caregiverImageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'startTime': startTime,
      'endTime': endTime,
      'bookingType': bookingType.name,
      'services': services,
      'specialRequirements': specialRequirements,
      'hourlyRate': hourlyRate,
      'totalHours': totalHours,
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'finalAmount': finalAmount,
      'status': status.name,
      'cancellationReason': cancellationReason,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,
      'caregiverPhone': caregiverPhone,
    };
  }

  // Create from Firestore map
  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      caregiverImageUrl: map['caregiverImageUrl'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      startTime: map['startTime'],
      endTime: map['endTime'],
      bookingType: _parseBookingType(map['bookingType']),
      services: List<String>.from(map['services'] ?? []),
      specialRequirements: map['specialRequirements'],
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      totalHours: map['totalHours'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      finalAmount: (map['finalAmount'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      cancellationReason: map['cancellationReason'],
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      confirmedAt: map['confirmedAt'] != null ? (map['confirmedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      cancelledAt: map['cancelledAt'] != null ? (map['cancelledAt'] as Timestamp).toDate() : null,
      isPaid: map['isPaid'] ?? false,
      paymentId: map['paymentId'],
      clientAddress: map['clientAddress'],
      clientPhone: map['clientPhone'],
      caregiverPhone: map['caregiverPhone'],
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'inProgress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'rejected':
        return BookingStatus.rejected;
      default:
        return BookingStatus.pending;
    }
  }

  static BookingType _parseBookingType(String? type) {
    return type == 'recurring' ? BookingType.recurring : BookingType.oneTime;
  }

  BookingModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? caregiverId,
    String? caregiverName,
    String? caregiverImageUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    BookingType? bookingType,
    List<String>? services,
    String? specialRequirements,
    double? hourlyRate,
    int? totalHours,
    double? totalAmount,
    double? platformFee,
    double? finalAmount,
    BookingStatus? status,
    String? cancellationReason,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    bool? isPaid,
    String? paymentId,
    Map<String, dynamic>? clientAddress,
    String? clientPhone,
    String? caregiverPhone,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      caregiverId: caregiverId ?? this.caregiverId,
      caregiverName: caregiverName ?? this.caregiverName,
      caregiverImageUrl: caregiverImageUrl ?? this.caregiverImageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      bookingType: bookingType ?? this.bookingType,
      services: services ?? this.services,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalHours: totalHours ?? this.totalHours,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      isPaid: isPaid ?? this.isPaid,
      paymentId: paymentId ?? this.paymentId,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
    );
  }
}
