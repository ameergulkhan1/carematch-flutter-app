import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';

/// Booking model - extends entity and adds Firebase serialization
class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.bookingRequestId,
    required super.clientId,
    required super.clientName,
    required super.caregiverId,
    required super.caregiverName,
    super.caregiverImageUrl,
    required super.startDate,
    required super.endDate,
    super.startTime,
    super.endTime,
    required super.bookingType,
    required super.serviceType,
    required super.services,
    super.specialRequirements,
    required super.tasks,
    required super.medicationRequired,
    required super.mobilityHelpRequired,
    required super.mealPrepRequired,
    required super.schoolPickupRequired,
    super.carePlanDetails,
    required super.hourlyRate,
    required super.totalHours,
    required super.totalAmount,
    required super.platformFee,
    required super.finalAmount,
    required super.status,
    super.cancellationReason,
    super.rejectionReason,
    super.disputeReason,
    super.requestMessage,
    required super.createdAt,
    super.acceptedAt,
    super.pendingPaymentAt,
    super.confirmedAt,
    super.sessionStartedAt,
    super.sessionEndedAt,
    super.completedAt,
    super.cancelledAt,
    super.disputedAt,
    required super.isPaid,
    super.paymentId,
    super.paymentMethod,
    super.paymentTransactionId,
    super.sessionPhotos = const [],
    super.sessionNotes,
    super.completedTasks = const [],
    super.isReviewed = false,
    super.reviewId,
  });

  /// Convert entity to model
  factory BookingModel.fromEntity(BookingEntity entity) {
    return BookingModel(
      id: entity.id,
      bookingRequestId: entity.bookingRequestId,
      clientId: entity.clientId,
      clientName: entity.clientName,
      caregiverId: entity.caregiverId,
      caregiverName: entity.caregiverName,
      caregiverImageUrl: entity.caregiverImageUrl,
      startDate: entity.startDate,
      endDate: entity.endDate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      bookingType: entity.bookingType,
      serviceType: entity.serviceType,
      services: entity.services,
      specialRequirements: entity.specialRequirements,
      tasks: entity.tasks,
      medicationRequired: entity.medicationRequired,
      mobilityHelpRequired: entity.mobilityHelpRequired,
      mealPrepRequired: entity.mealPrepRequired,
      schoolPickupRequired: entity.schoolPickupRequired,
      carePlanDetails: entity.carePlanDetails,
      hourlyRate: entity.hourlyRate,
      totalHours: entity.totalHours,
      totalAmount: entity.totalAmount,
      platformFee: entity.platformFee,
      finalAmount: entity.finalAmount,
      status: entity.status,
      cancellationReason: entity.cancellationReason,
      rejectionReason: entity.rejectionReason,
      disputeReason: entity.disputeReason,
      requestMessage: entity.requestMessage,
      createdAt: entity.createdAt,
      acceptedAt: entity.acceptedAt,
      pendingPaymentAt: entity.pendingPaymentAt,
      confirmedAt: entity.confirmedAt,
      sessionStartedAt: entity.sessionStartedAt,
      sessionEndedAt: entity.sessionEndedAt,
      completedAt: entity.completedAt,
      cancelledAt: entity.cancelledAt,
      disputedAt: entity.disputedAt,
      isPaid: entity.isPaid,
      paymentId: entity.paymentId,
      paymentMethod: entity.paymentMethod,
      paymentTransactionId: entity.paymentTransactionId,
      sessionPhotos: entity.sessionPhotos,
      sessionNotes: entity.sessionNotes,
      completedTasks: entity.completedTasks,
      isReviewed: entity.isReviewed,
      reviewId: entity.reviewId,
    );
  }

  /// Create from Firestore document
  factory BookingModel.fromFirestore(String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      bookingRequestId: data['bookingRequestId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      caregiverName: data['caregiverName'] ?? '',
      caregiverImageUrl: data['caregiverImageUrl'],
      startDate: _parseDateTime(data['startDate']),
      endDate: _parseDateTime(data['endDate']),
      startTime: data['startTime'],
      endTime: data['endTime'],
      bookingType: _parseBookingType(data['bookingType']),
      serviceType: _parseServiceType(data['serviceType']),
      services: List<String>.from(data['services'] ?? []),
      specialRequirements: data['specialRequirements'],
      tasks: List<String>.from(data['tasks'] ?? []),
      medicationRequired: data['medicationRequired'] ?? false,
      mobilityHelpRequired: data['mobilityHelpRequired'] ?? false,
      mealPrepRequired: data['mealPrepRequired'] ?? false,
      schoolPickupRequired: data['schoolPickupRequired'] ?? false,
      carePlanDetails: data['carePlanDetails'],
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      totalHours: (data['totalHours'] ?? 0).toInt(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      finalAmount: (data['finalAmount'] ?? 0).toDouble(),
      status: _parseBookingStatus(data['status']),
      cancellationReason: data['cancellationReason'],
      rejectionReason: data['rejectionReason'],
      disputeReason: data['disputeReason'],
      requestMessage: data['requestMessage'],
      createdAt: _parseDateTime(data['createdAt']),
      acceptedAt: data['acceptedAt'] != null ? _parseDateTime(data['acceptedAt']) : null,
      pendingPaymentAt:
          data['pendingPaymentAt'] != null ? _parseDateTime(data['pendingPaymentAt']) : null,
      confirmedAt: data['confirmedAt'] != null ? _parseDateTime(data['confirmedAt']) : null,
      sessionStartedAt:
          data['sessionStartedAt'] != null ? _parseDateTime(data['sessionStartedAt']) : null,
      sessionEndedAt:
          data['sessionEndedAt'] != null ? _parseDateTime(data['sessionEndedAt']) : null,
      completedAt: data['completedAt'] != null ? _parseDateTime(data['completedAt']) : null,
      cancelledAt: data['cancelledAt'] != null ? _parseDateTime(data['cancelledAt']) : null,
      disputedAt: data['disputedAt'] != null ? _parseDateTime(data['disputedAt']) : null,
      isPaid: data['isPaid'] ?? false,
      paymentId: data['paymentId'],
      paymentMethod: data['paymentMethod'],
      paymentTransactionId: data['paymentTransactionId'],
      sessionPhotos: List<String>.from(data['sessionPhotos'] ?? []),
      sessionNotes: data['sessionNotes'],
      completedTasks: List<String>.from(data['completedTasks'] ?? []),
      isReviewed: data['isReviewed'] ?? false,
      reviewId: data['reviewId'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookingRequestId': bookingRequestId,
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
      'serviceType': serviceType.name,
      'services': services,
      'specialRequirements': specialRequirements,
      'tasks': tasks,
      'medicationRequired': medicationRequired,
      'mobilityHelpRequired': mobilityHelpRequired,
      'mealPrepRequired': mealPrepRequired,
      'schoolPickupRequired': schoolPickupRequired,
      'carePlanDetails': carePlanDetails,
      'hourlyRate': hourlyRate,
      'totalHours': totalHours,
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'finalAmount': finalAmount,
      'status': status.name,
      'cancellationReason': cancellationReason,
      'rejectionReason': rejectionReason,
      'disputeReason': disputeReason,
      'requestMessage': requestMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'pendingPaymentAt': pendingPaymentAt != null ? Timestamp.fromDate(pendingPaymentAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'sessionStartedAt':
          sessionStartedAt != null ? Timestamp.fromDate(sessionStartedAt!) : null,
      'sessionEndedAt': sessionEndedAt != null ? Timestamp.fromDate(sessionEndedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'disputedAt': disputedAt != null ? Timestamp.fromDate(disputedAt!) : null,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'paymentTransactionId': paymentTransactionId,
      'sessionPhotos': sessionPhotos,
      'sessionNotes': sessionNotes,
      'completedTasks': completedTasks,
      'isReviewed': isReviewed,
      'reviewId': reviewId,
    };
  }

  /// Helper to parse DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  /// Helper to parse BookingStatus
  static BookingStatus _parseBookingStatus(dynamic value) {
    if (value is String) {
      return BookingStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => BookingStatus.pending,
      );
    }
    return BookingStatus.pending;
  }

  /// Helper to parse BookingType
  static BookingType _parseBookingType(dynamic value) {
    if (value is String) {
      return BookingType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => BookingType.oneTime,
      );
    }
    return BookingType.oneTime;
  }

  /// Helper to parse ServiceType
  static ServiceType _parseServiceType(dynamic value) {
    if (value is String) {
      return ServiceType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ServiceType.other,
      );
    }
    return ServiceType.other;
  }
}
