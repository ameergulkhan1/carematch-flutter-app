import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/incident_report_model.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class IncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  /// Generate unique incident number
  Future<String> _generateIncidentNumber() async {
    final year = DateTime.now().year;
    final snapshot = await _firestore
        .collection('incidents')
        .where('incidentNumber', isGreaterThanOrEqualTo: 'INC-$year-')
        .where('incidentNumber', isLessThan: 'INC-${year + 1}-')
        .orderBy('incidentNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'INC-$year-000001';
    }

    final lastNumber = snapshot.docs.first['incidentNumber'] as String;
    final lastSequence = int.parse(lastNumber.split('-').last);
    final newSequence = (lastSequence + 1).toString().padLeft(6, '0');
    return 'INC-$year-$newSequence';
  }

  /// Upload evidence file to Firebase Storage
  Future<IncidentEvidence?> uploadEvidence({
    required File file,
    required String incidentId,
    required String uploadedBy,
    required String fileType,
    String? description,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'incident_evidence/$incidentId/${timestamp}_$fileName';

      final uploadTask = _storage.ref(storagePath).putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return IncidentEvidence(
        id: timestamp.toString(),
        fileName: fileName,
        fileUrl: downloadUrl,
        fileType: fileType,
        uploadedAt: DateTime.now(),
        uploadedBy: uploadedBy,
        description: description,
      );
    } catch (e) {
      print('Error uploading evidence: $e');
      return null;
    }
  }

  /// Create new incident report
  Future<String?> createIncidentReport({
    required IncidentType type,
    required IncidentSeverity severity,
    required String reporterId,
    required String reporterName,
    required String reporterRole,
    String? bookingId,
    String? caregiverId,
    String? caregiverName,
    String? clientId,
    String? clientName,
    required String title,
    required String description,
    required DateTime incidentDate,
    List<IncidentEvidence>? evidence,
    List<String>? tags,
  }) async {
    try {
      final incidentNumber = await _generateIncidentNumber();
      final now = DateTime.now();

      final initialTimeline = [
        InvestigationTimeline(
          timestamp: now,
          action: 'Incident reported',
          performedBy: reporterName,
          notes: 'Initial report submitted by $reporterRole',
        ),
      ];

      final incident = IncidentReport(
        id: '',
        incidentNumber: incidentNumber,
        type: type,
        severity: severity,
        status: IncidentStatus.submitted,
        reporterId: reporterId,
        reporterName: reporterName,
        reporterRole: reporterRole,
        bookingId: bookingId,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        clientId: clientId,
        clientName: clientName,
        title: title,
        description: description,
        incidentDate: incidentDate,
        reportedAt: now,
        evidence: evidence ?? [],
        timeline: initialTimeline,
        tags: tags ?? [],
        notifyAuthorities: severity == IncidentSeverity.critical,
      );

      final docRef = await _firestore.collection('incidents').add(incident.toMap());

      // Send notification to admin
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: 'admin',
          type: NotificationType.general,
          title: 'New Incident Report',
          message: 'Severity: ${severity.name.toUpperCase()} - $title',
          data: {
            'incidentId': docRef.id,
            'incidentNumber': incidentNumber,
            'severity': severity.name,
            'type': type.name,
          },
          createdAt: DateTime.now(),
        ),
      );

      // Send notification to involved parties
      if (caregiverId != null && caregiverId != reporterId) {
        await _notificationService.createNotification(
          NotificationModel(
            id: '',
            userId: caregiverId,
            type: NotificationType.general,
            title: 'Incident Report Filed',
            message: 'An incident has been reported involving you. Incident #$incidentNumber',
            data: {'incidentId': docRef.id},
            createdAt: DateTime.now(),
          ),
        );
      }

      if (clientId != null && clientId != reporterId) {
        await _notificationService.createNotification(
          NotificationModel(
            id: '',
            userId: clientId,
            type: NotificationType.general,
            title: 'Incident Report Filed',
            message: 'An incident has been reported involving you. Incident #$incidentNumber',
            data: {'incidentId': docRef.id},
            createdAt: DateTime.now(),
          ),
        );
      }

      return docRef.id;
    } catch (e) {
      print('Error creating incident report: $e');
      return null;
    }
  }

  /// Update incident status
  Future<bool> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required String performedBy,
    required String performedByName,
    String? notes,
  }) async {
    try {
      final incident = await getIncidentById(incidentId);
      if (incident == null) return false;

      final newTimeline = List<InvestigationTimeline>.from(incident.timeline);
      newTimeline.add(InvestigationTimeline(
        timestamp: DateTime.now(),
        action: 'Status changed to ${newStatus.name}',
        performedBy: performedByName,
        notes: notes,
      ));

      await _firestore.collection('incidents').doc(incidentId).update({
        'status': newStatus.name,
        'timeline': newTimeline.map((t) => t.toMap()).toList(),
      });

      // Notify reporter
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: incident.reporterId,
          type: NotificationType.general,
          title: 'Incident Update',
          message: 'Incident #${incident.incidentNumber} status: ${newStatus.name}',
          data: {'incidentId': incidentId},
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error updating incident status: $e');
      return false;
    }
  }

  /// Assign incident to admin for investigation
  Future<bool> assignIncident({
    required String incidentId,
    required String assignedTo,
    required String assignedToName,
    required String assignedBy,
    required String assignedByName,
  }) async {
    try {
      final incident = await getIncidentById(incidentId);
      if (incident == null) return false;

      final newTimeline = List<InvestigationTimeline>.from(incident.timeline);
      newTimeline.add(InvestigationTimeline(
        timestamp: DateTime.now(),
        action: 'Assigned to $assignedToName',
        performedBy: assignedByName,
        notes: 'Incident assigned for investigation',
      ));

      await _firestore.collection('incidents').doc(incidentId).update({
        'assignedTo': assignedTo,
        'assignedToName': assignedToName,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': IncidentStatus.underReview.name,
        'timeline': newTimeline.map((t) => t.toMap()).toList(),
      });

      // Notify assigned admin
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: assignedTo,
          type: NotificationType.general,
          title: 'Incident Assigned',
          message: 'You have been assigned to investigate incident #${incident.incidentNumber}',
          data: {'incidentId': incidentId},
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error assigning incident: $e');
      return false;
    }
  }

  /// Add investigation notes
  Future<bool> addInvestigationNotes({
    required String incidentId,
    required String notes,
    required String performedBy,
    required String performedByName,
  }) async {
    try {
      final incident = await getIncidentById(incidentId);
      if (incident == null) return false;

      final newTimeline = List<InvestigationTimeline>.from(incident.timeline);
      newTimeline.add(InvestigationTimeline(
        timestamp: DateTime.now(),
        action: 'Investigation notes added',
        performedBy: performedByName,
        notes: notes,
      ));

      await _firestore.collection('incidents').doc(incidentId).update({
        'investigationNotes': notes,
        'status': IncidentStatus.investigating.name,
        'timeline': newTimeline.map((t) => t.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('Error adding investigation notes: $e');
      return false;
    }
  }

  /// Resolve incident
  Future<bool> resolveIncident({
    required String incidentId,
    required String resolutionNotes,
    required String resolvedBy,
    required String resolvedByName,
    required bool actionTaken,
    String? actionDetails,
  }) async {
    try {
      final incident = await getIncidentById(incidentId);
      if (incident == null) return false;

      final newTimeline = List<InvestigationTimeline>.from(incident.timeline);
      newTimeline.add(InvestigationTimeline(
        timestamp: DateTime.now(),
        action: 'Incident resolved',
        performedBy: resolvedByName,
        notes: resolutionNotes,
      ));

      await _firestore.collection('incidents').doc(incidentId).update({
        'status': IncidentStatus.resolved.name,
        'resolutionNotes': resolutionNotes,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': resolvedBy,
        'actionTaken': actionTaken,
        'actionDetails': actionDetails,
        'timeline': newTimeline.map((t) => t.toMap()).toList(),
      });

      // Notify reporter
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: incident.reporterId,
          type: NotificationType.general,
          title: 'Incident Resolved',
          message: 'Incident #${incident.incidentNumber} has been resolved',
          data: {
            'incidentId': incidentId,
            'resolutionNotes': resolutionNotes,
          },
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error resolving incident: $e');
      return false;
    }
  }

  /// Escalate incident
  Future<bool> escalateIncident({
    required String incidentId,
    required String performedBy,
    required String performedByName,
    required String escalationReason,
  }) async {
    try {
      final incident = await getIncidentById(incidentId);
      if (incident == null) return false;

      final newTimeline = List<InvestigationTimeline>.from(incident.timeline);
      newTimeline.add(InvestigationTimeline(
        timestamp: DateTime.now(),
        action: 'Incident escalated',
        performedBy: performedByName,
        notes: escalationReason,
      ));

      await _firestore.collection('incidents').doc(incidentId).update({
        'status': IncidentStatus.escalated.name,
        'severity': IncidentSeverity.critical.name,
        'notifyAuthorities': true,
        'timeline': newTimeline.map((t) => t.toMap()).toList(),
      });

      // Send critical alert to all admins
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: 'admin',
          type: NotificationType.general,
          title: '🚨 ESCALATED INCIDENT',
          message: 'CRITICAL: Incident #${incident.incidentNumber} has been escalated',
          data: {
            'incidentId': incidentId,
            'escalationReason': escalationReason,
          },
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error escalating incident: $e');
      return false;
    }
  }

  /// Get incident by ID
  Future<IncidentReport?> getIncidentById(String incidentId) async {
    try {
      final doc = await _firestore.collection('incidents').doc(incidentId).get();
      if (!doc.exists) return null;
      return IncidentReport.fromMap(doc.id, doc.data()!);
    } catch (e) {
      print('Error getting incident: $e');
      return null;
    }
  }

  /// Get all incidents (admin) with filters
  Stream<List<IncidentReport>> getIncidents({
    IncidentStatus? status,
    IncidentSeverity? severity,
    IncidentType? type,
    String? assignedTo,
  }) {
    Query query = _firestore.collection('incidents').orderBy('reportedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (severity != null) {
      query = query.where('severity', isEqualTo: severity.name);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (assignedTo != null) {
      query = query.where('assignedTo', isEqualTo: assignedTo);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return IncidentReport.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Get user's incidents (client or caregiver)
  Stream<List<IncidentReport>> getUserIncidents(String userId, {String? role}) {
    Query query = _firestore.collection('incidents');

    if (role == 'client') {
      query = query.where('clientId', isEqualTo: userId);
    } else if (role == 'caregiver') {
      query = query.where('caregiverId', isEqualTo: userId);
    } else {
      query = query.where('reporterId', isEqualTo: userId);
    }

    return query.orderBy('reportedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return IncidentReport.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Get booking-related incidents
  Stream<List<IncidentReport>> getBookingIncidents(String bookingId) {
    return _firestore
        .collection('incidents')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // ignore: unnecessary_cast
        return IncidentReport.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Get critical/unresolved incidents
  Stream<List<IncidentReport>> getCriticalIncidents() {
    return _firestore
        .collection('incidents')
        .where('severity', isEqualTo: IncidentSeverity.critical.name)
        .where('status', whereIn: [
          IncidentStatus.submitted.name,
          IncidentStatus.underReview.name,
          IncidentStatus.investigating.name,
          IncidentStatus.escalated.name,
        ])
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // ignore: unnecessary_cast
            return IncidentReport.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  /// Get incident statistics
  Future<Map<String, dynamic>> getIncidentStats() async {
    try {
      final allIncidents = await _firestore.collection('incidents').get();

      int total = allIncidents.docs.length;
      int resolved = 0;
      int pending = 0;
      int critical = 0;
      int escalated = 0;

      Map<String, int> byType = {};
      Map<String, int> bySeverity = {};

      for (var doc in allIncidents.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final severity = data['severity'] as String?;
        final type = data['type'] as String?;

        if (status == IncidentStatus.resolved.name) resolved++;
        if (status == IncidentStatus.submitted.name ||
            status == IncidentStatus.underReview.name ||
            status == IncidentStatus.investigating.name) {
          pending++;
        }
        if (severity == IncidentSeverity.critical.name) critical++;
        if (status == IncidentStatus.escalated.name) escalated++;

        if (type != null) {
          byType[type] = (byType[type] ?? 0) + 1;
        }
        if (severity != null) {
          bySeverity[severity] = (bySeverity[severity] ?? 0) + 1;
        }
      }

      return {
        'total': total,
        'resolved': resolved,
        'pending': pending,
        'critical': critical,
        'escalated': escalated,
        'byType': byType,
        'bySeverity': bySeverity,
        'resolutionRate': total > 0 ? (resolved / total * 100).toStringAsFixed(1) : '0.0',
      };
    } catch (e) {
      print('Error getting incident stats: $e');
      return {
        'total': 0,
        'resolved': 0,
        'pending': 0,
        'critical': 0,
        'escalated': 0,
        'byType': {},
        'bySeverity': {},
        'resolutionRate': '0.0',
      };
    }
  }
}
