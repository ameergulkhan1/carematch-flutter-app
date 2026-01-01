import 'package:equatable/equatable.dart';

/// Booking status enumeration
enum BookingStatus {
  pending,
  pendingPayment,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
  disputed,
  resolved,
  pendingReschedule,
}

/// Booking type enumeration
enum BookingType {
  oneTime,
  recurring,
}

/// Service type enumeration
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

/// Pure Dart booking entity - NO Firebase/Flutter dependencies
class BookingEntity extends Equatable {
  final String id;
  final String bookingRequestId;

  // Participants
  final String clientId;
  final String clientName;
  final String caregiverId;
  final String caregiverName;
  final String? caregiverImageUrl;

  // Booking details
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final BookingType bookingType;
  final ServiceType serviceType;
  final List<String> services;
  final String? specialRequirements;

  // Care plan
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

  // Status
  final BookingStatus status;
  final String? cancellationReason;
  final String? rejectionReason;
  final String? disputeReason;
  final String? requestMessage;

  // Timestamps
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pendingPaymentAt;
  final DateTime? confirmedAt;
  final DateTime? sessionStartedAt;
  final DateTime? sessionEndedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? disputedAt;

  // Payment
  final bool isPaid;
  final String? paymentId;
  final String? paymentMethod;
  final String? paymentTransactionId;

  // Session execution
  final List<String> sessionPhotos;
  final String? sessionNotes;
  final List<String> completedTasks;

  // Review
  final bool isReviewed;
  final String? reviewId;

  const BookingEntity({
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
    required this.tasks,
    required this.medicationRequired,
    required this.mobilityHelpRequired,
    required this.mealPrepRequired,
    required this.schoolPickupRequired,
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
    required this.isPaid,
    this.paymentId,
    this.paymentMethod,
    this.paymentTransactionId,
    this.sessionPhotos = const [],
    this.sessionNotes,
    this.completedTasks = const [],
    this.isReviewed = false,
    this.reviewId,
  });

  @override
  List<Object?> get props => [
        id,
        bookingRequestId,
        clientId,
        clientName,
        caregiverId,
        caregiverName,
        caregiverImageUrl,
        startDate,
        endDate,
        startTime,
        endTime,
        bookingType,
        serviceType,
        services,
        specialRequirements,
        tasks,
        medicationRequired,
        mobilityHelpRequired,
        mealPrepRequired,
        schoolPickupRequired,
        carePlanDetails,
        hourlyRate,
        totalHours,
        totalAmount,
        platformFee,
        finalAmount,
        status,
        cancellationReason,
        rejectionReason,
        disputeReason,
        requestMessage,
        createdAt,
        acceptedAt,
        pendingPaymentAt,
        confirmedAt,
        sessionStartedAt,
        sessionEndedAt,
        completedAt,
        cancelledAt,
        disputedAt,
        isPaid,
        paymentId,
        paymentMethod,
        paymentTransactionId,
        sessionPhotos,
        sessionNotes,
        completedTasks,
        isReviewed,
        reviewId,
      ];
}

/// Booking request parameters for creating a new booking
class CreateBookingParams extends Equatable {
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
  final ServiceType serviceType;
  final List<String> services;
  final String? specialRequirements;
  final List<String> tasks;
  final bool medicationRequired;
  final bool mobilityHelpRequired;
  final bool mealPrepRequired;
  final bool schoolPickupRequired;
  final String? carePlanDetails;
  final double hourlyRate;
  final int totalHours;
  final String? requestMessage;

  const CreateBookingParams({
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
    required this.tasks,
    required this.medicationRequired,
    required this.mobilityHelpRequired,
    required this.mealPrepRequired,
    required this.schoolPickupRequired,
    this.carePlanDetails,
    required this.hourlyRate,
    required this.totalHours,
    this.requestMessage,
  });

  @override
  List<Object?> get props => [
        clientId,
        clientName,
        caregiverId,
        caregiverName,
        caregiverImageUrl,
        startDate,
        endDate,
        startTime,
        endTime,
        bookingType,
        serviceType,
        services,
        specialRequirements,
        tasks,
        medicationRequired,
        mobilityHelpRequired,
        mealPrepRequired,
        schoolPickupRequired,
        carePlanDetails,
        hourlyRate,
        totalHours,
        requestMessage,
      ];
}

/// Parameters for updating booking status
class UpdateBookingStatusParams extends Equatable {
  final String bookingId;
  final BookingStatus newStatus;
  final String? reason; // For cancellation, rejection, or dispute

  const UpdateBookingStatusParams({
    required this.bookingId,
    required this.newStatus,
    this.reason,
  });

  @override
  List<Object?> get props => [bookingId, newStatus, reason];
}

/// Parameters for starting a booking session
class StartSessionParams extends Equatable {
  final String bookingId;
  final DateTime startTime;

  const StartSessionParams({
    required this.bookingId,
    required this.startTime,
  });

  @override
  List<Object?> get props => [bookingId, startTime];
}

/// Parameters for ending a booking session
class EndSessionParams extends Equatable {
  final String bookingId;
  final DateTime endTime;
  final List<String> sessionPhotos;
  final String? sessionNotes;
  final List<String> completedTasks;

  const EndSessionParams({
    required this.bookingId,
    required this.endTime,
    this.sessionPhotos = const [],
    this.sessionNotes,
    this.completedTasks = const [],
  });

  @override
  List<Object?> get props => [
        bookingId,
        endTime,
        sessionPhotos,
        sessionNotes,
        completedTasks,
      ];
}
