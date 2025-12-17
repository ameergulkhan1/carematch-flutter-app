import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/review_model.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Profanity and inappropriate content filter
  final List<String> _profanityList = [
    'spam', 'scam', 'fake', 'fraud', // Add more as needed
  ];

  /// Upload review photo
  Future<String?> uploadReviewPhoto({
    required File file,
    required String reviewerId,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'review_photos/$reviewerId/${timestamp}_$fileName';

      final uploadTask = _storage.ref(storagePath).putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading review photo: $e');
      return null;
    }
  }

  /// Auto-moderate content for profanity/spam
  bool _containsInappropriateContent(String text) {
    final lowerText = text.toLowerCase();
    return _profanityList.any((word) => lowerText.contains(word));
  }

  /// Create a new review with auto-moderation
  Future<String?> createReviewWithModeration({
    required Review review,
  }) async {
    try {
      // Auto-moderate content
      bool needsModeration = _containsInappropriateContent(review.comment);

      final reviewToCreate = review.copyWith(
        isFlagged: needsModeration,
        isVisible: !needsModeration, // Hide if flagged
      );

      final docRef = await _firestore.collection('reviews').add(reviewToCreate.toMap());
      
      // Update caregiver's average rating only if visible
      if (review.reviewerType == 'client' && !needsModeration) {
        await _updateCaregiverRating(review.revieweeId);
      }

      // Notify if auto-moderated
      if (needsModeration) {
        await _notificationService.createNotification(
          NotificationModel(
            id: '',
            userId: 'admin',
            type: NotificationType.general,
            title: 'Review Auto-Flagged',
            message: 'A review was automatically flagged for moderation',
            data: {'reviewId': docRef.id},
            createdAt: DateTime.now(),
          ),
        );
      }
      
      return docRef.id;
    } catch (e) {
      print('Error creating review: $e');
      return null;
    }
  }

  /// Create a new review
  Future<String?> createReview(Review review) async {
    try {
      final docRef = await _firestore.collection('reviews').add(review.toMap());
      
      // Update caregiver's average rating
      if (review.reviewerType == 'client') {
        await _updateCaregiverRating(review.revieweeId);
      }
      
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating review: $e');
      return null;
    }
  }

  /// Get reviews for a caregiver
  Stream<List<Review>> getCaregiverReviews(String caregiverId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: caregiverId)
        .where('reviewerType', isEqualTo: 'client')
        .where('isVisible', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get reviews written by a client
  Stream<List<Review>> getClientReviews(String clientId) {
    return _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: clientId)
        .where('reviewerType', isEqualTo: 'client')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get review for a specific booking
  Future<Review?> getBookingReview(String bookingId, String reviewerId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('reviewerId', isEqualTo: reviewerId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Review.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting booking review: $e');
      return null;
    }
  }

  /// Update a review
  Future<bool> updateReview(String reviewId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting review: $e');
      return false;
    }
  }

  /// Hide/unhide a review (moderation)
  Future<bool> toggleReviewVisibility(String reviewId, bool isVisible) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isVisible': isVisible,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error toggling review visibility: $e');
      return false;
    }
  }

  /// Calculate and update caregiver's average rating
  Future<void> _updateCaregiverRating(String caregiverId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: caregiverId)
          .where('reviewerType', isEqualTo: 'client')
          .where('isVisible', isEqualTo: true)
          .get();

      if (reviews.docs.isEmpty) return;

      double totalRating = 0;
      int count = 0;

      for (var doc in reviews.docs) {
        final review = Review.fromMap(doc.id, doc.data());
        totalRating += review.rating;
        count++;
      }

      final averageRating = totalRating / count;

      // Update caregiver's profile with new rating
      await _firestore.collection('caretaker_profiles').doc(caregiverId).update({
        'averageRating': averageRating,
        'totalReviews': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error updating caregiver rating: $e');
    }
  }

  /// Get average rating for a caregiver
  Future<double> getCaregiverAverageRating(String caregiverId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: caregiverId)
          .where('reviewerType', isEqualTo: 'client')
          .where('isVisible', isEqualTo: true)
          .get();

      if (reviews.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var doc in reviews.docs) {
        final review = Review.fromMap(doc.id, doc.data());
        totalRating += review.rating;
      }

      return totalRating / reviews.docs.length;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  /// Get all reviews (admin)
  Stream<List<Review>> getAllReviews() {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get flagged/reported reviews (for moderation)
  Stream<List<Review>> getFlaggedReviews() {
    return _firestore
        .collection('reviews')
        .where('isFlagged', isEqualTo: true)
        .orderBy('flaggedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Report/flag a review
  Future<bool> reportReview({
    required String reviewId,
    required String flaggedBy,
    required String flagReason,
  }) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isFlagged': true,
        'flaggedBy': flaggedBy,
        'flagReason': flagReason,
        'flaggedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify admins
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: 'admin',
          type: NotificationType.general,
          title: 'Review Flagged',
          message: 'A review has been reported for: $flagReason',
          data: {'reviewId': reviewId, 'flagReason': flagReason},
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error reporting review: $e');
      return false;
    }
  }

  /// Moderate review (admin action)
  Future<bool> moderateReview({
    required String reviewId,
    required String moderatedBy,
    required bool isVisible,
    String? moderationNotes,
  }) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isVisible': isVisible,
        'moderatedBy': moderatedBy,
        'moderationNotes': moderationNotes,
        'moderatedAt': FieldValue.serverTimestamp(),
        'isFlagged': false, // Clear flag after moderation
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error moderating review: $e');
      return false;
    }
  }

  /// Get pending moderation reviews
  Stream<List<Review>> getPendingModerationReviews() {
    return _firestore
        .collection('reviews')
        .where('isFlagged', isEqualTo: true)
        .where('moderatedBy', isEqualTo: null)
        .orderBy('flaggedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Add admin response to review
  Future<bool> addAdminResponse({
    required String reviewId,
    required String response,
  }) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'adminResponse': response,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding admin response: $e');
      return false;
    }
  }

  /// Hide review (admin action)
  Future<bool> hideReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isVisible': false,
        'moderatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error hiding review: $e');
      return false;
    }
  }

  /// Approve review (admin action)
  Future<bool> approveReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isVisible': true,
        'isFlagged': false,
        'moderatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error approving review: $e');
      return false;
    }
  }

  /// Unflag review (admin action)
  Future<bool> unflagReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isFlagged': false,
        'flagReason': null,
        'moderatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error unflagging review: $e');
      return false;
    }
  }
}
