import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types
enum NotificationType {
  verificationApproved,
  verificationRejected,
  revisionRequested,
  bookingConfirmed,
  bookingCancelled,
  bookingCompleted,
  paymentReceived,
  reviewReceived,
  sessionReminder,
  documentExpiring,
  general,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional data (adminNotes, rejectionReason, etc.)
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: _parseNotificationType(map['type']),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.general;

    switch (typeString) {
      case 'verification_approved':
        return NotificationType.verificationApproved;
      case 'verification_rejected':
        return NotificationType.verificationRejected;
      case 'revision_requested':
        return NotificationType.revisionRequested;
      case 'booking_confirmed':
        return NotificationType.bookingConfirmed;
      case 'booking_cancelled':
        return NotificationType.bookingCancelled;
      case 'booking_completed':
        return NotificationType.bookingCompleted;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'review_received':
        return NotificationType.reviewReceived;
      case 'session_reminder':
        return NotificationType.sessionReminder;
      case 'document_expiring':
        return NotificationType.documentExpiring;
      default:
        return NotificationType.general;
    }
  }

  /// Copy with method
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
