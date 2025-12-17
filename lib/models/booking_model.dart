import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,           // Initial request created
  pendingPayment,    // Caregiver accepted, awaiting payment
  confirmed,         // Payment successful, booking confirmed
  inProgress,        // Service started
  completed,         // Service completed, awaiting review
  cancelled,         // Cancelled by client
  rejected,          // Rejected by caregiver
  disputed,          // Dispute raised
  resolved,          // Dispute resolved
  pendingReschedule, // Reschedule requested, awaiting approval
}

enum BookingType {
  oneTime,
  recurring,
}

enum ServiceType {
  childcare,
  eldercare,
  specialNeeds,
  companionship,
  medicalCare,
  dementiaCare,
  mealPreparation,
  transportation,
  housekeeping,
  other,
}

enum PaymentMethod {
  card,
  wallet,
  bankTransfer,
}

class BookingModel {
  final String id;
  final String bookingRequestId; // Format: BKG-2025-000182
  
  // Client & Caregiver Info
  final String clientId;
  final String clientName;
  final String caregiverId;
  final String caregiverName;
  final String? caregiverImageUrl;
  
  // Booking Details
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final BookingType bookingType;
  final ServiceType serviceType;
  final List<String> services;
  final String? specialRequirements;
  
  // Care Plan
  final List<String> tasks;
  final bool medicationRequired;
  final bool mobilityHelpRequired;
  final bool mealPrepRequired;
  final bool schoolPickupRequired;
  final String? carePlanDetails;
  
  // Pricing
  final double hourlyRate;
  final int totalHours;
  final double totalAmount;
  final double platformFee;
  final double finalAmount;
  
  // Status & Flow
  final BookingStatus status;
  final String? cancellationReason;
  final String? rejectionReason;
  final String? disputeReason;
  final String? requestMessage; // Client's initial message
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? acceptedAt;      // Stage 5: Caregiver accepted
  final DateTime? pendingPaymentAt; // Stage 5: Moved to payment
  final DateTime? confirmedAt;      // Stage 7: Payment confirmed
  final DateTime? sessionStartedAt; // Stage 9: Session started
  final DateTime? sessionEndedAt;   // Stage 9: Session ended
  final DateTime? completedAt;      // Stage 10: Client approved
  final DateTime? cancelledAt;
  final DateTime? disputedAt;
  
  // Payment
  final bool isPaid;
  final String? paymentId;
  final String? paymentMethod;
  final String? paymentTransactionId;
  
  // Session Execution (Stage 9)
  final List<Map<String, dynamic>> taskCompletionLogs; // {task, completed, timestamp}
  final List<String> sessionPhotos; // Photo URLs
  final String? sessionNotes;
  
  // Post-Service (Stage 10)
  final String? clientApprovalStatus; // 'approved', 'disputed', 'pending'
  final int? rating; // 1-5 star rating
  final String? review; // Written review/feedback
  final DateTime? ratedAt; // When rating was submitted
  
  // Payout (Stage 11)
  final bool payoutReleased;
  final String? walletTransactionId;
  final DateTime? payoutReleasedAt;
  
  // Admin Oversight (Stage 13)
  final String? adminReviewedBy;
  final String? adminNotes;
  final DateTime? adminReviewedAt;
  
  // Contact Info
  final Map<String, dynamic>? clientAddress;
  final String? clientPhone;
  final String? clientPhoneCountryCode;
  final String? clientPhoneDialCode;
  final String? caregiverPhone;
  final String? caregiverPhoneCountryCode;
  final String? caregiverPhoneDialCode;

  BookingModel({
    required this.id,
    required this.bookingRequestId,
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
    required this.serviceType,
    required this.services,
    this.specialRequirements,
    this.tasks = const [],
    this.medicationRequired = false,
    this.mobilityHelpRequired = false,
    this.mealPrepRequired = false,
    this.schoolPickupRequired = false,
    this.carePlanDetails,
    required this.hourlyRate,
    required this.totalHours,
    required this.totalAmount,
    required this.platformFee,
    required this.finalAmount,
    required this.status,
    this.cancellationReason,
    this.rejectionReason,
    this.disputeReason,
    this.requestMessage,
    required this.createdAt,
    this.acceptedAt,
    this.pendingPaymentAt,
    this.confirmedAt,
    this.sessionStartedAt,
    this.sessionEndedAt,
    this.completedAt,
    this.cancelledAt,
    this.disputedAt,
    this.isPaid = false,
    this.paymentId,
    this.paymentMethod,
    this.paymentTransactionId,
    this.taskCompletionLogs = const [],
    this.sessionPhotos = const [],
    this.sessionNotes,
    this.clientApprovalStatus,
    this.rating,
    this.review,
    this.ratedAt,
    this.payoutReleased = false,
    this.walletTransactionId,
    this.payoutReleasedAt,
    this.adminReviewedBy,
    this.adminNotes,
    this.adminReviewedAt,
    this.clientAddress,
    this.clientPhone,
    this.clientPhoneCountryCode,
    this.clientPhoneDialCode,
    this.caregiverPhone,
    this.caregiverPhoneCountryCode,
    this.caregiverPhoneDialCode,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
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
      'sessionStartedAt': sessionStartedAt != null ? Timestamp.fromDate(sessionStartedAt!) : null,
      'sessionEndedAt': sessionEndedAt != null ? Timestamp.fromDate(sessionEndedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'disputedAt': disputedAt != null ? Timestamp.fromDate(disputedAt!) : null,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'paymentTransactionId': paymentTransactionId,
      'taskCompletionLogs': taskCompletionLogs,
      'sessionPhotos': sessionPhotos,
      'sessionNotes': sessionNotes,
      'clientApprovalStatus': clientApprovalStatus,
      'rating': rating,
      'review': review,
      'ratedAt': ratedAt?.toIso8601String(),
      'payoutReleased': payoutReleased,
      'walletTransactionId': walletTransactionId,
      'payoutReleasedAt': payoutReleasedAt != null ? Timestamp.fromDate(payoutReleasedAt!) : null,
      'adminReviewedBy': adminReviewedBy,
      'adminNotes': adminNotes,
      'adminReviewedAt': adminReviewedAt != null ? Timestamp.fromDate(adminReviewedAt!) : null,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,
      'clientPhoneCountryCode': clientPhoneCountryCode,
      'clientPhoneDialCode': clientPhoneDialCode,
      'caregiverPhone': caregiverPhone,
      'caregiverPhoneCountryCode': caregiverPhoneCountryCode,
      'caregiverPhoneDialCode': caregiverPhoneDialCode,
    };
  }

  // Create from Firestore map
  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      bookingRequestId: map['bookingRequestId'] ?? 'BKG-${DateTime.now().year}-${id.substring(0, 6)}',
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
      serviceType: _parseServiceType(map['serviceType']),
      services: List<String>.from(map['services'] ?? []),
      specialRequirements: map['specialRequirements'],
      tasks: List<String>.from(map['tasks'] ?? []),
      medicationRequired: map['medicationRequired'] ?? false,
      mobilityHelpRequired: map['mobilityHelpRequired'] ?? false,
      mealPrepRequired: map['mealPrepRequired'] ?? false,
      schoolPickupRequired: map['schoolPickupRequired'] ?? false,
      carePlanDetails: map['carePlanDetails'],
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      totalHours: map['totalHours'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      finalAmount: (map['finalAmount'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      cancellationReason: map['cancellationReason'],
      rejectionReason: map['rejectionReason'],
      disputeReason: map['disputeReason'],
      requestMessage: map['requestMessage'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null ? (map['acceptedAt'] as Timestamp).toDate() : null,
      pendingPaymentAt: map['pendingPaymentAt'] != null ? (map['pendingPaymentAt'] as Timestamp).toDate() : null,
      confirmedAt: map['confirmedAt'] != null ? (map['confirmedAt'] as Timestamp).toDate() : null,
      sessionStartedAt: map['sessionStartedAt'] != null ? (map['sessionStartedAt'] as Timestamp).toDate() : null,
      sessionEndedAt: map['sessionEndedAt'] != null ? (map['sessionEndedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      cancelledAt: map['cancelledAt'] != null ? (map['cancelledAt'] as Timestamp).toDate() : null,
      disputedAt: map['disputedAt'] != null ? (map['disputedAt'] as Timestamp).toDate() : null,
      isPaid: map['isPaid'] ?? false,
      paymentId: map['paymentId'],
      paymentMethod: map['paymentMethod'],
      paymentTransactionId: map['paymentTransactionId'],
      taskCompletionLogs: List<Map<String, dynamic>>.from(map['taskCompletionLogs'] ?? []),
      sessionPhotos: List<String>.from(map['sessionPhotos'] ?? []),
      sessionNotes: map['sessionNotes'],
      clientApprovalStatus: map['clientApprovalStatus'],
      rating: map['rating'],
      review: map['review'],
      ratedAt: map['ratedAt'] != null
          ? (map['ratedAt'] is Timestamp
              ? (map['ratedAt'] as Timestamp).toDate()
              : DateTime.parse(map['ratedAt']))
          : null,
      payoutReleased: map['payoutReleased'] ?? false,
      walletTransactionId: map['walletTransactionId'],
      payoutReleasedAt: map['payoutReleasedAt'] != null ? (map['payoutReleasedAt'] as Timestamp).toDate() : null,
      adminReviewedBy: map['adminReviewedBy'],
      adminNotes: map['adminNotes'],
      adminReviewedAt: map['adminReviewedAt'] != null ? (map['adminReviewedAt'] as Timestamp).toDate() : null,
      clientAddress: map['clientAddress'],
      clientPhone: map['clientPhone'],
      clientPhoneCountryCode: map['clientPhoneCountryCode'],
      clientPhoneDialCode: map['clientPhoneDialCode'],
      caregiverPhone: map['caregiverPhone'],
      caregiverPhoneCountryCode: map['caregiverPhoneCountryCode'],
      caregiverPhoneDialCode: map['caregiverPhoneDialCode'],
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'pendingPayment':
        return BookingStatus.pendingPayment;
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
      case 'disputed':
        return BookingStatus.disputed;
      case 'resolved':
        return BookingStatus.resolved;
      default:
        return BookingStatus.pending;
    }
  }

  static BookingType _parseBookingType(String? type) {
    return type == 'recurring' ? BookingType.recurring : BookingType.oneTime;
  }

  static ServiceType _parseServiceType(String? type) {
    switch (type) {
      case 'childcare':
        return ServiceType.childcare;
      case 'eldercare':
        return ServiceType.eldercare;
      case 'specialNeeds':
        return ServiceType.specialNeeds;
      case 'companionship':
        return ServiceType.companionship;
      case 'medicalCare':
        return ServiceType.medicalCare;
      case 'dementiaCare':
        return ServiceType.dementiaCare;
      case 'mealPreparation':
        return ServiceType.mealPreparation;
      case 'transportation':
        return ServiceType.transportation;
      case 'housekeeping':
        return ServiceType.housekeeping;
      default:
        return ServiceType.other;
    }
  }

  BookingModel copyWith({
    String? id,
    String? bookingRequestId,
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
    ServiceType? serviceType,
    List<String>? services,
    String? specialRequirements,
    List<String>? tasks,
    bool? medicationRequired,
    bool? mobilityHelpRequired,
    bool? mealPrepRequired,
    bool? schoolPickupRequired,
    String? carePlanDetails,
    double? hourlyRate,
    int? totalHours,
    double? totalAmount,
    double? platformFee,
    double? finalAmount,
    BookingStatus? status,
    String? cancellationReason,
    String? rejectionReason,
    String? disputeReason,
    String? requestMessage,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? pendingPaymentAt,
    DateTime? confirmedAt,
    DateTime? sessionStartedAt,
    DateTime? sessionEndedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? disputedAt,
    bool? isPaid,
    String? paymentId,
    String? paymentMethod,
    String? paymentTransactionId,
    List<Map<String, dynamic>>? taskCompletionLogs,
    List<String>? sessionPhotos,
    String? sessionNotes,
    String? clientApprovalStatus,
    int? rating,
    String? review,
    DateTime? ratedAt,
    bool? payoutReleased,
    String? walletTransactionId,
    DateTime? payoutReleasedAt,
    String? adminReviewedBy,
    String? adminNotes,
    DateTime? adminReviewedAt,
    Map<String, dynamic>? clientAddress,
    String? clientPhone,
    String? caregiverPhone,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingRequestId: bookingRequestId ?? this.bookingRequestId,
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
      serviceType: serviceType ?? this.serviceType,
      services: services ?? this.services,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      tasks: tasks ?? this.tasks,
      medicationRequired: medicationRequired ?? this.medicationRequired,
      mobilityHelpRequired: mobilityHelpRequired ?? this.mobilityHelpRequired,
      mealPrepRequired: mealPrepRequired ?? this.mealPrepRequired,
      schoolPickupRequired: schoolPickupRequired ?? this.schoolPickupRequired,
      carePlanDetails: carePlanDetails ?? this.carePlanDetails,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalHours: totalHours ?? this.totalHours,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      disputeReason: disputeReason ?? this.disputeReason,
      requestMessage: requestMessage ?? this.requestMessage,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pendingPaymentAt: pendingPaymentAt ?? this.pendingPaymentAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      sessionEndedAt: sessionEndedAt ?? this.sessionEndedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      disputedAt: disputedAt ?? this.disputedAt,
      isPaid: isPaid ?? this.isPaid,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      taskCompletionLogs: taskCompletionLogs ?? this.taskCompletionLogs,
      sessionPhotos: sessionPhotos ?? this.sessionPhotos,
      sessionNotes: sessionNotes ?? this.sessionNotes,
      clientApprovalStatus: clientApprovalStatus ?? this.clientApprovalStatus,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      ratedAt: ratedAt ?? this.ratedAt,
      payoutReleased: payoutReleased ?? this.payoutReleased,
      walletTransactionId: walletTransactionId ?? this.walletTransactionId,
      payoutReleasedAt: payoutReleasedAt ?? this.payoutReleasedAt,
      adminReviewedBy: adminReviewedBy ?? this.adminReviewedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      adminReviewedAt: adminReviewedAt ?? this.adminReviewedAt,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
    );
  }
}
