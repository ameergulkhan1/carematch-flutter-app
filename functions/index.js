const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * Auto-escalate critical incidents
 * Triggers when a new incident is created with critical severity
 */
exports.autoEscalateCriticalIncidents = functions.firestore
  .document('incidents/{incidentId}')
  .onCreate(async (snap, context) => {
    const incident = snap.data();
    const incidentId = context.params.incidentId;

    // Check if incident is critical severity
    if (incident.severity === 'critical') {
      try {
        // Create admin alert
        await db.collection('admin_alerts').add({
          type: 'critical_incident',
          title: `Critical Incident: ${incident.incidentNumber}`,
          message: `A critical incident has been reported: ${incident.title}`,
          incidentId: incidentId,
          incidentNumber: incident.incidentNumber,
          severity: incident.severity,
          reporterId: incident.reporterId,
          reporterName: incident.reporterName,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          priority: 'urgent',
        });

        // Update incident with auto-escalation flag
        await snap.ref.update({
          autoEscalated: true,
          escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
          escalationReason: 'Automatically escalated due to critical severity',
        });

        // Send notifications to all admins
        const adminsSnapshot = await db
          .collection('users')
          .where('role', '==', 'admin')
          .get();

        const notificationPromises = adminsSnapshot.docs.map((adminDoc) => {
          return db.collection('notifications').add({
            userId: adminDoc.id,
            title: '🚨 Critical Incident Alert',
            message: `${incident.incidentNumber}: ${incident.title}`,
            type: 'critical_incident',
            relatedId: incidentId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            priority: 'high',
          });
        });

        await Promise.all(notificationPromises);

        console.log(`Critical incident ${incidentId} auto-escalated successfully`);
      } catch (error) {
        console.error('Error auto-escalating critical incident:', error);
      }
    }
  });

/**
 * Monitor low ratings and create incidents
 * Triggers when a new review is created with rating <= 2.0
 */
exports.monitorLowRatings = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const review = snap.data();
    const reviewId = context.params.reviewId;

    // Check if rating is 2.0 or lower
    if (review.rating <= 2.0) {
      try {
        // Get current incident count for numbering
        const incidentsSnapshot = await db
          .collection('incidents')
          .orderBy('createdAt', 'desc')
          .limit(1)
          .get();

        let incidentNumber = 1;
        if (!incidentsSnapshot.empty) {
          const lastIncident = incidentsSnapshot.docs[0].data();
          const lastNumber = parseInt(lastIncident.incidentNumber.split('-')[2]);
          incidentNumber = lastNumber + 1;
        }

        const formattedNumber = `INC-${new Date().getFullYear()}-${String(incidentNumber).padStart(6, '0')}`;

        // Create automatic incident report
        const incidentData = {
          incidentNumber: formattedNumber,
          type: 'serviceQualityIssue',
          severity: review.rating <= 1.5 ? 'high' : 'medium',
          status: 'reported',
          reporterId: 'system',
          reporterName: 'Automated System',
          reporterRole: 'system',
          bookingId: review.bookingId,
          caregiverId: review.revieweeId,
          caregiverName: review.revieweeName,
          clientId: review.reviewerId,
          clientName: review.reviewerName,
          title: `Low Rating Alert: ${review.rating.toFixed(1)} stars`,
          description: `Automatically generated incident due to low rating (${review.rating.toFixed(1)}/5.0).\n\nReview Comment: ${review.comment || 'No comment provided'}`,
          incidentDate: review.createdAt,
          location: null,
          tags: ['low-rating', 'auto-generated', 'service-quality'],
          evidence: [],
          investigationTimeline: [
            {
              action: 'Incident Created',
              performedBy: 'System',
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              notes: 'Auto-generated from low rating review',
            },
          ],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          assignedTo: null,
          assignedToName: null,
          resolution: null,
          resolvedAt: null,
          resolvedBy: null,
          escalatedAt: null,
          escalatedBy: null,
          closedAt: null,
        };

        const incidentRef = await db.collection('incidents').add(incidentData);

        // Create notification for caregiver
        await db.collection('notifications').add({
          userId: review.revieweeId,
          title: 'Low Rating Received',
          message: 'A low rating has triggered an automatic quality review. Please review the feedback.',
          type: 'incident_created',
          relatedId: incidentRef.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          priority: 'medium',
        });

        // Notify admins about low rating
        const adminsSnapshot = await db
          .collection('users')
          .where('role', '==', 'admin')
          .get();

        const adminNotifications = adminsSnapshot.docs.map((adminDoc) => {
          return db.collection('notifications').add({
            userId: adminDoc.id,
            title: 'Low Rating Alert',
            message: `${review.revieweeName} received a ${review.rating.toFixed(1)} star rating. Incident ${formattedNumber} created.`,
            type: 'low_rating_alert',
            relatedId: incidentRef.id,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            priority: 'medium',
          });
        });

        await Promise.all(adminNotifications);

        console.log(`Low rating incident created: ${formattedNumber} for review ${reviewId}`);
      } catch (error) {
        console.error('Error creating low rating incident:', error);
      }
    }
  });

/**
 * Scheduled metrics calculation
 * Runs every Sunday at 00:00 UTC
 */
exports.scheduledMetricsCalculation = functions.pubsub
  .schedule('0 0 * * 0') // Every Sunday at midnight
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Starting scheduled metrics calculation...');

    try {
      // Get all active caregivers
      const caregiversSnapshot = await db
        .collection('users')
        .where('role', '==', 'caregiver')
        .where('isActive', '==', true)
        .get();

      const calculationPromises = [];
      const now = new Date();
      const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

      for (const caregiverDoc of caregiversSnapshot.docs) {
        const caregiverId = caregiverDoc.id;

        // Calculate metrics for this caregiver
        const metricsPromise = calculateCaregiverMetrics(caregiverId, ninetyDaysAgo, now);
        calculationPromises.push(metricsPromise);
      }

      const results = await Promise.allSettled(calculationPromises);
      
      const successful = results.filter((r) => r.status === 'fulfilled').length;
      const failed = results.filter((r) => r.status === 'rejected').length;

      console.log(`Metrics calculation completed: ${successful} successful, ${failed} failed`);

      // Calculate platform-wide metrics
      await calculatePlatformMetrics();

      return null;
    } catch (error) {
      console.error('Error in scheduled metrics calculation:', error);
      throw error;
    }
  });

/**
 * Helper function to calculate caregiver metrics
 */
async function calculateCaregiverMetrics(caregiverId, startDate, endDate) {
  const [bookingsSnapshot, reviewsSnapshot, incidentsSnapshot] = await Promise.all([
    db.collection('bookings')
      .where('caregiverId', '==', caregiverId)
      .where('createdAt', '>=', startDate)
      .where('createdAt', '<=', endDate)
      .get(),
    db.collection('reviews')
      .where('revieweeId', '==', caregiverId)
      .where('createdAt', '>=', startDate)
      .where('createdAt', '<=', endDate)
      .get(),
    db.collection('incidents')
      .where('caregiverId', '==', caregiverId)
      .where('createdAt', '>=', startDate)
      .where('createdAt', '<=', endDate)
      .get(),
  ]);

  const bookings = bookingsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const reviews = reviewsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const incidents = incidentsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  // Calculate response metrics
  const responseTimes = bookings
    .filter((b) => b.acceptedAt)
    .map((b) => {
      const created = b.createdAt.toDate();
      const accepted = b.acceptedAt.toDate();
      return (accepted - created) / (1000 * 60 * 60); // hours
    });

  const averageResponseTime = responseTimes.length > 0
    ? responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length
    : 0;

  const acceptanceRate = bookings.length > 0
    ? (bookings.filter((b) => b.status !== 'cancelled' && b.acceptedAt).length / bookings.length) * 100
    : 0;

  // Calculate completion metrics
  const completedBookings = bookings.filter((b) => b.status === 'completed');
  const completionRate = bookings.length > 0 ? (completedBookings.length / bookings.length) * 100 : 0;
  const cancelledByCaregiver = bookings.filter((b) => b.status === 'cancelled' && b.cancelledBy === caregiverId).length;
  const noShows = bookings.filter((b) => b.status === 'no_show').length;

  // Calculate satisfaction metrics
  const ratings = reviews.map((r) => r.rating);
  const averageRating = ratings.length > 0 ? ratings.reduce((a, b) => a + b, 0) / ratings.length : 0;

  const starDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  reviews.forEach((r) => {
    const star = Math.round(r.rating);
    starDistribution[star] = (starDistribution[star] || 0) + 1;
  });

  // Calculate issue metrics
  const criticalIncidents = incidents.filter((i) => i.severity === 'critical').length;

  // Calculate engagement metrics
  const totalHoursWorked = completedBookings.reduce((sum, b) => {
    if (b.startTime && b.endTime) {
      const start = b.startTime.toDate();
      const end = b.endTime.toDate();
      return sum + (end - start) / (1000 * 60 * 60);
    }
    return sum;
  }, 0);

  const uniqueClients = [...new Set(completedBookings.map((b) => b.clientId))];
  const repeatClients = uniqueClients.filter((clientId) => {
    return completedBookings.filter((b) => b.clientId === clientId).length > 1;
  });
  const clientRetentionRate = uniqueClients.length > 0
    ? (repeatClients.length / uniqueClients.length) * 100
    : 0;

  // Calculate quality score
  const qualityScore = calculateQualityScore({
    acceptanceRate,
    completionRate,
    averageRating,
    totalIncidents: incidents.length,
    criticalIncidents,
    clientRetentionRate,
  });

  // Determine performance tier
  const performanceTier = getPerformanceTier(qualityScore);

  // Create metrics document
  const metricsData = {
    caregiverId,
    calculationPeriodStart: admin.firestore.Timestamp.fromDate(startDate),
    calculationPeriodEnd: admin.firestore.Timestamp.fromDate(endDate),
    averageResponseTime,
    acceptanceRate,
    completionRate,
    cancelledByCaregiver,
    noShows,
    totalBookings: bookings.length,
    completedBookings: completedBookings.length,
    averageRating,
    totalReviews: reviews.length,
    starDistribution,
    totalIncidents: incidents.length,
    criticalIncidents,
    totalHoursWorked,
    repeatClients: repeatClients.length,
    clientRetentionRate,
    qualityScore,
    performanceTier,
    needsAttention: qualityScore < 70 || averageRating < 3.5 || criticalIncidents > 0,
    calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('quality_metrics').add(metricsData);

  return metricsData;
}

/**
 * Helper function to calculate platform metrics
 */
async function calculatePlatformMetrics() {
  const metricsSnapshot = await db
    .collection('quality_metrics')
    .orderBy('calculatedAt', 'desc')
    .limit(1000)
    .get();

  if (metricsSnapshot.empty) return;

  const allMetrics = metricsSnapshot.docs.map((doc) => doc.data());

  const platformData = {
    totalCaregivers: allMetrics.length,
    averageQualityScore: allMetrics.reduce((sum, m) => sum + m.qualityScore, 0) / allMetrics.length,
    averageRating: allMetrics.reduce((sum, m) => sum + m.averageRating, 0) / allMetrics.length,
    averageCompletionRate: allMetrics.reduce((sum, m) => sum + m.completionRate, 0) / allMetrics.length,
    caregiverPerformanceTiers: {
      excellent: allMetrics.filter((m) => m.performanceTier === 'Excellent').length,
      veryGood: allMetrics.filter((m) => m.performanceTier === 'Very Good').length,
      good: allMetrics.filter((m) => m.performanceTier === 'Good').length,
      satisfactory: allMetrics.filter((m) => m.performanceTier === 'Satisfactory').length,
      needsImprovement: allMetrics.filter((m) => m.performanceTier === 'Needs Improvement').length,
    },
    caregiverStatistics: {
      highPerformers: allMetrics.filter((m) => m.qualityScore >= 85).length,
      needingAttention: allMetrics.filter((m) => m.needsAttention).length,
      withCriticalIncidents: allMetrics.filter((m) => m.criticalIncidents > 0).length,
    },
    calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('platform_metrics').add(platformData);

  return platformData;
}

/**
 * Calculate quality score based on multiple factors
 */
function calculateQualityScore(metrics) {
  const acceptanceScore = metrics.acceptanceRate * 0.2;
  const completionScore = metrics.completionRate * 0.25;
  const ratingScore = (metrics.averageRating / 5.0) * 100 * 0.3;
  
  let incidentPenalty = metrics.totalIncidents * 5;
  incidentPenalty += metrics.criticalIncidents * 15;
  incidentPenalty = Math.min(incidentPenalty, 30);
  
  const retentionScore = metrics.clientRetentionRate * 0.1;
  
  const score = acceptanceScore + completionScore + ratingScore + retentionScore - incidentPenalty;
  
  return Math.max(0, Math.min(100, score));
}

/**
 * Get performance tier based on quality score
 */
function getPerformanceTier(score) {
  if (score >= 90) return 'Excellent';
  if (score >= 80) return 'Very Good';
  if (score >= 70) return 'Good';
  if (score >= 60) return 'Satisfactory';
  return 'Needs Improvement';
}

/**
 * Update caregiver metrics when a booking is completed
 */
exports.onBookingCompleted = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if booking status changed to completed
    if (before.status !== 'completed' && after.status === 'completed') {
      try {
        const now = new Date();
        const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

        // Recalculate metrics for this caregiver
        await calculateCaregiverMetrics(after.caregiverId, ninetyDaysAgo, now);

        console.log(`Metrics updated for caregiver ${after.caregiverId} after booking completion`);
      } catch (error) {
        console.error('Error updating metrics on booking completion:', error);
      }
    }
  });
