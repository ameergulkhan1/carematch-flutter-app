import 'package:cloud_firestore/cloud_firestore.dart';

/// Quality metrics model for tracking caregiver performance
class QualityMetrics {
  final String id;
  final String caregiverId;
  final String caregiverName;

  // Response metrics
  final double averageResponseTime; // In hours
  final int totalRequests;
  final int acceptedRequests;
  final int rejectedRequests;
  final double acceptanceRate; // Percentage

  // Completion metrics
  final int totalBookings;
  final int completedBookings;
  final int cancelledByCaregiver;
  final int noShows;
  final double completionRate; // Percentage

  // Satisfaction metrics
  final double averageRating;
  final int totalReviews;
  final Map<String, double>? averageDetailedRatings; // e.g., professionalism, punctuality
  final int fiveStarReviews;
  final int fourStarReviews;
  final int threeStarReviews;
  final int twoStarReviews;
  final int oneStarReviews;

  // Quality issues
  final int totalIncidents;
  final int criticalIncidents;
  final int resolvedIncidents;
  final int clientComplaints;
  final int warnings;

  // Engagement metrics
  final int totalHoursWorked;
  final int repeatClients;
  final double clientRetentionRate; // Percentage
  final DateTime? lastActiveDate;
  final int daysActive;

  // Timestamps
  final DateTime calculatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;

  QualityMetrics({
    required this.id,
    required this.caregiverId,
    required this.caregiverName,
    required this.averageResponseTime,
    required this.totalRequests,
    required this.acceptedRequests,
    required this.rejectedRequests,
    required this.acceptanceRate,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledByCaregiver,
    required this.noShows,
    required this.completionRate,
    required this.averageRating,
    required this.totalReviews,
    this.averageDetailedRatings,
    required this.fiveStarReviews,
    required this.fourStarReviews,
    required this.threeStarReviews,
    required this.twoStarReviews,
    required this.oneStarReviews,
    required this.totalIncidents,
    required this.criticalIncidents,
    required this.resolvedIncidents,
    required this.clientComplaints,
    required this.warnings,
    required this.totalHoursWorked,
    required this.repeatClients,
    required this.clientRetentionRate,
    this.lastActiveDate,
    required this.daysActive,
    required this.calculatedAt,
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'averageResponseTime': averageResponseTime,
      'totalRequests': totalRequests,
      'acceptedRequests': acceptedRequests,
      'rejectedRequests': rejectedRequests,
      'acceptanceRate': acceptanceRate,
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'cancelledByCaregiver': cancelledByCaregiver,
      'noShows': noShows,
      'completionRate': completionRate,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'averageDetailedRatings': averageDetailedRatings,
      'fiveStarReviews': fiveStarReviews,
      'fourStarReviews': fourStarReviews,
      'threeStarReviews': threeStarReviews,
      'twoStarReviews': twoStarReviews,
      'oneStarReviews': oneStarReviews,
      'totalIncidents': totalIncidents,
      'criticalIncidents': criticalIncidents,
      'resolvedIncidents': resolvedIncidents,
      'clientComplaints': clientComplaints,
      'warnings': warnings,
      'totalHoursWorked': totalHoursWorked,
      'repeatClients': repeatClients,
      'clientRetentionRate': clientRetentionRate,
      'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'daysActive': daysActive,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
    };
  }

  factory QualityMetrics.fromMap(String id, Map<String, dynamic> map) {
    return QualityMetrics(
      id: id,
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      averageResponseTime: (map['averageResponseTime'] ?? 0.0).toDouble(),
      totalRequests: map['totalRequests'] ?? 0,
      acceptedRequests: map['acceptedRequests'] ?? 0,
      rejectedRequests: map['rejectedRequests'] ?? 0,
      acceptanceRate: (map['acceptanceRate'] ?? 0.0).toDouble(),
      totalBookings: map['totalBookings'] ?? 0,
      completedBookings: map['completedBookings'] ?? 0,
      cancelledByCaregiver: map['cancelledByCaregiver'] ?? 0,
      noShows: map['noShows'] ?? 0,
      completionRate: (map['completionRate'] ?? 0.0).toDouble(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      averageDetailedRatings: map['averageDetailedRatings'] != null
          ? Map<String, double>.from(map['averageDetailedRatings'])
          : null,
      fiveStarReviews: map['fiveStarReviews'] ?? 0,
      fourStarReviews: map['fourStarReviews'] ?? 0,
      threeStarReviews: map['threeStarReviews'] ?? 0,
      twoStarReviews: map['twoStarReviews'] ?? 0,
      oneStarReviews: map['oneStarReviews'] ?? 0,
      totalIncidents: map['totalIncidents'] ?? 0,
      criticalIncidents: map['criticalIncidents'] ?? 0,
      resolvedIncidents: map['resolvedIncidents'] ?? 0,
      clientComplaints: map['clientComplaints'] ?? 0,
      warnings: map['warnings'] ?? 0,
      totalHoursWorked: map['totalHoursWorked'] ?? 0,
      repeatClients: map['repeatClients'] ?? 0,
      clientRetentionRate: (map['clientRetentionRate'] ?? 0.0).toDouble(),
      lastActiveDate: map['lastActiveDate'] != null ? (map['lastActiveDate'] as Timestamp).toDate() : null,
      daysActive: map['daysActive'] ?? 0,
      calculatedAt: (map['calculatedAt'] as Timestamp).toDate(),
      periodStart: (map['periodStart'] as Timestamp).toDate(),
      periodEnd: (map['periodEnd'] as Timestamp).toDate(),
    );
  }

  /// Calculate quality score (0-100)
  double get qualityScore {
    double score = 0;

    // Acceptance rate (20 points)
    score += acceptanceRate * 0.2;

    // Completion rate (25 points)
    score += completionRate * 0.25;

    // Average rating (30 points)
    score += (averageRating / 5.0) * 30;

    // Incident penalty (subtract up to 15 points)
    if (totalBookings > 0) {
      final incidentRate = totalIncidents / totalBookings;
      score -= (incidentRate * 100).clamp(0, 15);
    }

    // Client retention bonus (10 points)
    score += clientRetentionRate * 0.1;

    return score.clamp(0, 100);
  }

  /// Get performance tier
  String get performanceTier {
    final score = qualityScore;
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Very Good';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Satisfactory';
    return 'Needs Improvement';
  }

  /// Check if caregiver needs attention
  bool get needsAttention {
    return completionRate < 80 ||
        averageRating < 3.5 ||
        criticalIncidents > 0 ||
        acceptanceRate < 50 ||
        clientComplaints > 2;
  }
}

/// Platform-wide quality metrics
class PlatformMetrics {
  final String id;
  final DateTime calculatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;

  // Overall stats
  final int totalCaregivers;
  final int activeCaregivers;
  final int totalClients;
  final int activeClients;
  final int totalBookings;
  final int completedBookings;

  // Quality averages
  final double averageResponseTime;
  final double averageCompletionRate;
  final double averageRating;
  final double averageAcceptanceRate;

  // Issue tracking
  final int totalIncidents;
  final int criticalIncidents;
  final int totalDisputes;
  final int resolvedDisputes;

  // Satisfaction
  final double overallSatisfactionScore;
  final int totalReviews;

  PlatformMetrics({
    required this.id,
    required this.calculatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.totalCaregivers,
    required this.activeCaregivers,
    required this.totalClients,
    required this.activeClients,
    required this.totalBookings,
    required this.completedBookings,
    required this.averageResponseTime,
    required this.averageCompletionRate,
    required this.averageRating,
    required this.averageAcceptanceRate,
    required this.totalIncidents,
    required this.criticalIncidents,
    required this.totalDisputes,
    required this.resolvedDisputes,
    required this.overallSatisfactionScore,
    required this.totalReviews,
  });

  Map<String, dynamic> toMap() {
    return {
      'calculatedAt': Timestamp.fromDate(calculatedAt),
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'totalCaregivers': totalCaregivers,
      'activeCaregivers': activeCaregivers,
      'totalClients': totalClients,
      'activeClients': activeClients,
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'averageResponseTime': averageResponseTime,
      'averageCompletionRate': averageCompletionRate,
      'averageRating': averageRating,
      'averageAcceptanceRate': averageAcceptanceRate,
      'totalIncidents': totalIncidents,
      'criticalIncidents': criticalIncidents,
      'totalDisputes': totalDisputes,
      'resolvedDisputes': resolvedDisputes,
      'overallSatisfactionScore': overallSatisfactionScore,
      'totalReviews': totalReviews,
    };
  }

  factory PlatformMetrics.fromMap(String id, Map<String, dynamic> map) {
    return PlatformMetrics(
      id: id,
      calculatedAt: (map['calculatedAt'] as Timestamp).toDate(),
      periodStart: (map['periodStart'] as Timestamp).toDate(),
      periodEnd: (map['periodEnd'] as Timestamp).toDate(),
      totalCaregivers: map['totalCaregivers'] ?? 0,
      activeCaregivers: map['activeCaregivers'] ?? 0,
      totalClients: map['totalClients'] ?? 0,
      activeClients: map['activeClients'] ?? 0,
      totalBookings: map['totalBookings'] ?? 0,
      completedBookings: map['completedBookings'] ?? 0,
      averageResponseTime: (map['averageResponseTime'] ?? 0.0).toDouble(),
      averageCompletionRate: (map['averageCompletionRate'] ?? 0.0).toDouble(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      averageAcceptanceRate: (map['averageAcceptanceRate'] ?? 0.0).toDouble(),
      totalIncidents: map['totalIncidents'] ?? 0,
      criticalIncidents: map['criticalIncidents'] ?? 0,
      totalDisputes: map['totalDisputes'] ?? 0,
      resolvedDisputes: map['resolvedDisputes'] ?? 0,
      overallSatisfactionScore: (map['overallSatisfactionScore'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
    );
  }

  double get platformHealth {
    double score = 0;
    score += (averageCompletionRate / 100) * 25;
    score += (averageRating / 5.0) * 25;
    score += (averageAcceptanceRate / 100) * 20;
    score += totalIncidents == 0 ? 15 : (15 * (1 - (totalIncidents / totalBookings).clamp(0, 1)));
    score += (overallSatisfactionScore / 5.0) * 15;
    return score.clamp(0, 100);
  }
}
