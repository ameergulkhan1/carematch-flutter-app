import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String reviewerId; // Client or caregiver who wrote the review
  final String reviewerName;
  final String revieweeId; // Person being reviewed
  final String revieweeName;
  final String reviewerType; // 'client' or 'caregiver'
  final double rating; // 1-5 stars
  final String comment;
  final Map<String, double>? detailedRatings; // e.g., professionalism, punctuality, care quality
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVisible;
  
  // Enhanced fields for Module 5
  final List<String> photos; // URLs of uploaded photos
  final bool isFlagged; // Whether review has been reported
  final String? flagReason; // Reason for flagging
  final String? flaggedBy; // User ID who flagged
  final DateTime? flaggedAt; // When it was flagged
  final String? moderationNotes; // Admin notes from moderation
  final String? moderatedBy; // Admin ID who moderated
  final DateTime? moderatedAt; // When it was moderated
  final bool isVerifiedBooking; // Whether review is from actual completed booking
  final String? adminResponse; // Admin response to review (if needed)

  Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeName,
    required this.reviewerType,
    required this.rating,
    required this.comment,
    this.detailedRatings,
    required this.createdAt,
    required this.updatedAt,
    this.isVisible = true,
    this.photos = const [],
    this.isFlagged = false,
    this.flagReason,
    this.flaggedBy,
    this.flaggedAt,
    this.moderationNotes,
    this.moderatedBy,
    this.moderatedAt,
    this.isVerifiedBooking = true,
    this.adminResponse,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'revieweeId': revieweeId,
      'revieweeName': revieweeName,
      'reviewerType': reviewerType,
      'rating': rating,
      'comment': comment,
      'detailedRatings': detailedRatings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVisible': isVisible,
      'photos': photos,
      'isFlagged': isFlagged,
      'flagReason': flagReason,
      'flaggedBy': flaggedBy,
      'flaggedAt': flaggedAt != null ? Timestamp.fromDate(flaggedAt!) : null,
      'moderationNotes': moderationNotes,
      'moderatedBy': moderatedBy,
      'moderatedAt': moderatedAt != null ? Timestamp.fromDate(moderatedAt!) : null,
      'isVerifiedBooking': isVerifiedBooking,
      'adminResponse': adminResponse,
    };
  }

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      bookingId: map['bookingId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      revieweeName: map['revieweeName'] ?? '',
      reviewerType: map['reviewerType'] ?? 'client',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      detailedRatings: map['detailedRatings'] != null
          ? Map<String, double>.from(map['detailedRatings'])
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isVisible: map['isVisible'] ?? true,
      photos: List<String>.from(map['photos'] ?? []),
      isFlagged: map['isFlagged'] ?? false,
      flagReason: map['flagReason'],
      flaggedBy: map['flaggedBy'],
      flaggedAt: map['flaggedAt'] != null ? (map['flaggedAt'] as Timestamp).toDate() : null,
      moderationNotes: map['moderationNotes'],
      moderatedBy: map['moderatedBy'],
      moderatedAt: map['moderatedAt'] != null ? (map['moderatedAt'] as Timestamp).toDate() : null,
      isVerifiedBooking: map['isVerifiedBooking'] ?? true,
      adminResponse: map['adminResponse'],
    );
  }

  Review copyWith({
    String? bookingId,
    String? reviewerId,
    String? reviewerName,
    String? revieweeId,
    String? revieweeName,
    String? reviewerType,
    double? rating,
    String? comment,
    Map<String, double>? detailedRatings,
    DateTime? updatedAt,
    bool? isVisible,
    List<String>? photos,
    bool? isFlagged,
    String? flagReason,
    String? flaggedBy,
    DateTime? flaggedAt,
    String? moderationNotes,
    String? moderatedBy,
    DateTime? moderatedAt,
    bool? isVerifiedBooking,
    String? adminResponse,
  }) {
    return Review(
      id: id,
      bookingId: bookingId ?? this.bookingId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      revieweeId: revieweeId ?? this.revieweeId,
      revieweeName: revieweeName ?? this.revieweeName,
      reviewerType: reviewerType ?? this.reviewerType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      detailedRatings: detailedRatings ?? this.detailedRatings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVisible: isVisible ?? this.isVisible,
      photos: photos ?? this.photos,
      isFlagged: isFlagged ?? this.isFlagged,
      flagReason: flagReason ?? this.flagReason,
      flaggedBy: flaggedBy ?? this.flaggedBy,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      isVerifiedBooking: isVerifiedBooking ?? this.isVerifiedBooking,
      adminResponse: adminResponse ?? this.adminResponse,
    );
  }

  // Helper method to get average of detailed ratings
  double get averageDetailedRating {
    if (detailedRatings == null || detailedRatings!.isEmpty) return rating;
    final sum = detailedRatings!.values.reduce((a, b) => a + b);
    return sum / detailedRatings!.length;
  }
}
