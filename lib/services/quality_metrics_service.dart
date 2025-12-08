import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quality_metrics_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/incident_report_model.dart';

class QualityMetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate quality metrics for a specific caregiver
  Future<QualityMetrics?> calculateCaregiverMetrics({
    required String caregiverId,
    required String caregiverName,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final start = periodStart ?? DateTime.now().subtract(const Duration(days: 90));
      final end = periodEnd ?? DateTime.now();

      // Get all bookings for this caregiver in the period
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('caregiverId', isEqualTo: caregiverId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      // Response time calculation
      double totalResponseTime = 0;
      int acceptedRequests = 0;
      int rejectedRequests = 0;
      int totalRequests = 0;
      int completedBookings = 0;
      int cancelledByCaregiver = 0;
      int noShows = 0;
      int totalHoursWorked = 0;
      Set<String> uniqueClients = {};
      DateTime? lastActiveDate;

      for (var doc in bookingsSnapshot.docs) {
        final booking = BookingModel.fromMap(doc.id, doc.data());
        totalRequests++;

        // Response time (time between creation and acceptance/rejection)
        if (booking.acceptedAt != null) {
          final responseTime = booking.acceptedAt!.difference(booking.createdAt).inHours;
          totalResponseTime += responseTime;
          acceptedRequests++;
          uniqueClients.add(booking.clientId);
        } else if (booking.status == BookingStatus.rejected) {
          rejectedRequests++;
        }

        // Completion stats
        if (booking.status == BookingStatus.completed) {
          completedBookings++;
          totalHoursWorked += booking.totalHours;
          if (lastActiveDate == null || booking.completedAt!.isAfter(lastActiveDate)) {
            lastActiveDate = booking.completedAt;
          }
        }

        // Cancellations
        if (booking.status == BookingStatus.cancelled && 
            booking.cancelledAt != null &&
            booking.sessionStartedAt == null) {
          cancelledByCaregiver++;
        }

        // No-shows (status in-progress but session never started)
        if (booking.status == BookingStatus.cancelled &&
            booking.sessionStartedAt == null &&
            DateTime.now().isAfter(booking.startDate)) {
          noShows++;
        }
      }

      final averageResponseTime = acceptedRequests > 0 
          ? totalResponseTime / acceptedRequests 
          : 0.0;
      final acceptanceRate = totalRequests > 0 
          ? (acceptedRequests / totalRequests * 100) 
          : 0.0;
      final completionRate = acceptedRequests > 0 
          ? (completedBookings / acceptedRequests * 100) 
          : 0.0;

      // Get reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: caregiverId)
          .where('isVisible', isEqualTo: true)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double totalRating = 0;
      int fiveStar = 0, fourStar = 0, threeStar = 0, twoStar = 0, oneStar = 0;
      Map<String, double> detailedRatingsSum = {};
      Map<String, int> detailedRatingsCount = {};

      for (var doc in reviewsSnapshot.docs) {
        final review = Review.fromMap(doc.id, doc.data());
        totalRating += review.rating;

        // Star distribution
        if (review.rating >= 4.5) fiveStar++;
        else if (review.rating >= 3.5) fourStar++;
        else if (review.rating >= 2.5) threeStar++;
        else if (review.rating >= 1.5) twoStar++;
        else oneStar++;

        // Detailed ratings
        if (review.detailedRatings != null) {
          review.detailedRatings!.forEach((key, value) {
            detailedRatingsSum[key] = (detailedRatingsSum[key] ?? 0) + value;
            detailedRatingsCount[key] = (detailedRatingsCount[key] ?? 0) + 1;
          });
        }
      }

      final averageRating = reviewsSnapshot.docs.isNotEmpty 
          ? totalRating / reviewsSnapshot.docs.length 
          : 0.0;

      Map<String, double>? averageDetailedRatings;
      if (detailedRatingsSum.isNotEmpty) {
        averageDetailedRatings = {};
        detailedRatingsSum.forEach((key, sum) {
          averageDetailedRatings![key] = sum / detailedRatingsCount[key]!;
        });
      }

      // Get incidents
      final incidentsSnapshot = await _firestore
          .collection('incidents')
          .where('caregiverId', isEqualTo: caregiverId)
          .where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('reportedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int totalIncidents = incidentsSnapshot.docs.length;
      int criticalIncidents = 0;
      int resolvedIncidents = 0;
      int clientComplaints = 0;

      for (var doc in incidentsSnapshot.docs) {
        final incident = IncidentReport.fromMap(doc.id, doc.data());
        if (incident.severity == IncidentSeverity.critical) criticalIncidents++;
        if (incident.status == IncidentStatus.resolved) resolvedIncidents++;
        if (incident.reporterRole == 'client') clientComplaints++;
      }

      // Calculate repeat clients
      final allBookingsSnapshot = await _firestore
          .collection('bookings')
          .where('caregiverId', isEqualTo: caregiverId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .get();

      Map<String, int> clientBookingCounts = {};
      for (var doc in allBookingsSnapshot.docs) {
        final booking = BookingModel.fromMap(doc.id, doc.data());
        clientBookingCounts[booking.clientId] = 
            (clientBookingCounts[booking.clientId] ?? 0) + 1;
      }

      final repeatClients = clientBookingCounts.values.where((count) => count > 1).length;
      final clientRetentionRate = uniqueClients.isNotEmpty 
          ? (repeatClients / uniqueClients.length * 100) 
          : 0.0;

      final daysActive = lastActiveDate != null 
          ? DateTime.now().difference(lastActiveDate).inDays 
          : 0;

      final metrics = QualityMetrics(
        id: '',
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        averageResponseTime: averageResponseTime,
        totalRequests: totalRequests,
        acceptedRequests: acceptedRequests,
        rejectedRequests: rejectedRequests,
        acceptanceRate: acceptanceRate,
        totalBookings: acceptedRequests,
        completedBookings: completedBookings,
        cancelledByCaregiver: cancelledByCaregiver,
        noShows: noShows,
        completionRate: completionRate,
        averageRating: averageRating,
        totalReviews: reviewsSnapshot.docs.length,
        averageDetailedRatings: averageDetailedRatings,
        fiveStarReviews: fiveStar,
        fourStarReviews: fourStar,
        threeStarReviews: threeStar,
        twoStarReviews: twoStar,
        oneStarReviews: oneStar,
        totalIncidents: totalIncidents,
        criticalIncidents: criticalIncidents,
        resolvedIncidents: resolvedIncidents,
        clientComplaints: clientComplaints,
        warnings: criticalIncidents, // Can be adjusted based on other criteria
        totalHoursWorked: totalHoursWorked,
        repeatClients: repeatClients,
        clientRetentionRate: clientRetentionRate,
        lastActiveDate: lastActiveDate,
        daysActive: daysActive,
        calculatedAt: DateTime.now(),
        periodStart: start,
        periodEnd: end,
      );

      // Save to Firestore
      await _firestore.collection('quality_metrics').add(metrics.toMap());
      
      return metrics;
    } catch (e) {
      print('Error calculating caregiver metrics: $e');
      return null;
    }
  }

  /// Get caregiver's latest quality metrics
  Future<QualityMetrics?> getCaregiverMetrics(String caregiverId) async {
    try {
      final snapshot = await _firestore
          .collection('quality_metrics')
          .where('caregiverId', isEqualTo: caregiverId)
          .orderBy('calculatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return QualityMetrics.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    } catch (e) {
      print('Error getting caregiver metrics: $e');
      return null;
    }
  }

  /// Get metrics history for a caregiver
  Stream<List<QualityMetrics>> getCaregiverMetricsHistory(String caregiverId) {
    return _firestore
        .collection('quality_metrics')
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('calculatedAt', descending: true)
        .limit(12) // Last 12 calculations
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return QualityMetrics.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Calculate platform-wide metrics
  Future<PlatformMetrics?> calculatePlatformMetrics({
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final start = periodStart ?? DateTime.now().subtract(const Duration(days: 30));
      final end = periodEnd ?? DateTime.now();

      // Count users
      final caregiversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'caregiver')
          .where('verificationStatus', isEqualTo: 'approved')
          .get();

      final clientsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'client')
          .get();

      // Get bookings in period
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int completedBookings = 0;
      Set<String> activeCaregivers = {};
      Set<String> activeClients = {};

      for (var doc in bookingsSnapshot.docs) {
        final booking = BookingModel.fromMap(doc.id, doc.data());
        if (booking.status == BookingStatus.completed) {
          completedBookings++;
          activeCaregivers.add(booking.caregiverId);
          activeClients.add(booking.clientId);
        }
      }

      // Get all quality metrics for average calculations
      final metricsSnapshot = await _firestore
          .collection('quality_metrics')
          .where('calculatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('calculatedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double totalResponseTime = 0;
      double totalCompletionRate = 0;
      double totalRating = 0;
      double totalAcceptanceRate = 0;
      int metricsCount = metricsSnapshot.docs.length;

      for (var doc in metricsSnapshot.docs) {
        final metrics = QualityMetrics.fromMap(doc.id, doc.data());
        totalResponseTime += metrics.averageResponseTime;
        totalCompletionRate += metrics.completionRate;
        totalRating += metrics.averageRating;
        totalAcceptanceRate += metrics.acceptanceRate;
      }

      // Get incidents
      final incidentsSnapshot = await _firestore
          .collection('incidents')
          .where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('reportedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int criticalIncidents = 0;
      for (var doc in incidentsSnapshot.docs) {
        final incident = IncidentReport.fromMap(doc.id, doc.data());
        if (incident.severity == IncidentSeverity.critical) criticalIncidents++;
      }

      // Get disputes
      final disputesSnapshot = await _firestore
          .collection('bookings')
          .where('status', whereIn: [BookingStatus.disputed.name, BookingStatus.resolved.name])
          .where('disputedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('disputedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      int resolvedDisputes = 0;
      for (var doc in disputesSnapshot.docs) {
        final booking = BookingModel.fromMap(doc.id, doc.data());
        if (booking.status == BookingStatus.resolved) resolvedDisputes++;
      }

      // Get reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('isVisible', isEqualTo: true)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double totalReviewRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        final review = Review.fromMap(doc.id, doc.data());
        totalReviewRating += review.rating;
      }

      final overallSatisfaction = reviewsSnapshot.docs.isNotEmpty 
          ? totalReviewRating / reviewsSnapshot.docs.length 
          : 0.0;

      final platformMetrics = PlatformMetrics(
        id: '',
        calculatedAt: DateTime.now(),
        periodStart: start,
        periodEnd: end,
        totalCaregivers: caregiversSnapshot.docs.length,
        activeCaregivers: activeCaregivers.length,
        totalClients: clientsSnapshot.docs.length,
        activeClients: activeClients.length,
        totalBookings: bookingsSnapshot.docs.length,
        completedBookings: completedBookings,
        averageResponseTime: metricsCount > 0 ? totalResponseTime / metricsCount : 0,
        averageCompletionRate: metricsCount > 0 ? totalCompletionRate / metricsCount : 0,
        averageRating: metricsCount > 0 ? totalRating / metricsCount : 0,
        averageAcceptanceRate: metricsCount > 0 ? totalAcceptanceRate / metricsCount : 0,
        totalIncidents: incidentsSnapshot.docs.length,
        criticalIncidents: criticalIncidents,
        totalDisputes: disputesSnapshot.docs.length,
        resolvedDisputes: resolvedDisputes,
        overallSatisfactionScore: overallSatisfaction,
        totalReviews: reviewsSnapshot.docs.length,
      );

      // Save to Firestore
      await _firestore.collection('platform_metrics').add(platformMetrics.toMap());

      return platformMetrics;
    } catch (e) {
      print('Error calculating platform metrics: $e');
      return null;
    }
  }

  /// Get latest platform metrics
  Future<PlatformMetrics?> getLatestPlatformMetrics() async {
    try {
      final snapshot = await _firestore
          .collection('platform_metrics')
          .orderBy('calculatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PlatformMetrics.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    } catch (e) {
      print('Error getting platform metrics: $e');
      return null;
    }
  }

  /// Get caregivers that need attention
  Future<List<QualityMetrics>> getCaregiversNeedingAttention() async {
    try {
      // Get latest metrics for all caregivers
      final snapshot = await _firestore
          .collection('quality_metrics')
          .orderBy('calculatedAt', descending: true)
          .get();

      // Group by caregiver and take latest
      Map<String, QualityMetrics> latestMetrics = {};
      for (var doc in snapshot.docs) {
        final metrics = QualityMetrics.fromMap(doc.id, doc.data());
        if (!latestMetrics.containsKey(metrics.caregiverId)) {
          latestMetrics[metrics.caregiverId] = metrics;
        }
      }

      // Filter those needing attention
      return latestMetrics.values.where((m) => m.needsAttention).toList();
    } catch (e) {
      print('Error getting caregivers needing attention: $e');
      return [];
    }
  }

  /// Get top performers
  Future<List<QualityMetrics>> getTopPerformers({int limit = 10}) async {
    try {
      // Get latest metrics for all caregivers
      final snapshot = await _firestore
          .collection('quality_metrics')
          .orderBy('calculatedAt', descending: true)
          .get();

      // Group by caregiver and take latest
      Map<String, QualityMetrics> latestMetrics = {};
      for (var doc in snapshot.docs) {
        final metrics = QualityMetrics.fromMap(doc.id, doc.data());
        if (!latestMetrics.containsKey(metrics.caregiverId)) {
          latestMetrics[metrics.caregiverId] = metrics;
        }
      }

      // Sort by quality score
      final sorted = latestMetrics.values.toList()
        ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

      return sorted.take(limit).toList();
    } catch (e) {
      print('Error getting top performers: $e');
      return [];
    }
  }
}
