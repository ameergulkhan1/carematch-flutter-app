import 'package:cloud_firestore/cloud_firestore.dart';

/// Severity levels for incident reports
enum IncidentSeverity {
  low,       // Minor issues, non-urgent
  medium,    // Moderate concerns requiring attention
  high,      // Serious issues requiring immediate attention
  critical,  // Safety-critical incidents requiring urgent action
}

/// Incident status workflow
enum IncidentStatus {
  submitted,      // Initial report submitted
  underReview,    // Admin reviewing the incident
  investigating,  // Active investigation in progress
  resolved,       // Incident resolved
  dismissed,      // Incident dismissed (no action required)
  escalated,      // Escalated to higher management or authorities
}

/// Types of incidents
enum IncidentType {
  safetyViolation,       // Safety protocol violations
  professionalMisconduct, // Unprofessional behavior
  serviceQualityIssue,   // Poor service quality
  clientComplaint,       // Client-initiated complaint
  caregiverComplaint,    // Caregiver-initiated complaint
  paymentDispute,        // Payment-related issues
  noShow,                // No-show or late arrival
  inappropriateBehavior, // Harassment, abuse, etc.
  damageToProperty,      // Property damage
  medicalIncident,       // Medical emergencies or issues
  other,                 // Other incidents
}

/// Evidence attachment model
class IncidentEvidence {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType; // 'photo', 'document', 'audio', 'video'
  final DateTime uploadedAt;
  final String uploadedBy;
  final String? description;

  IncidentEvidence({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedAt,
    required this.uploadedBy,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
      'description': description,
    };
  }

  factory IncidentEvidence.fromMap(Map<String, dynamic> map) {
    return IncidentEvidence(
      id: map['id'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? 'photo',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: map['uploadedBy'] ?? '',
      description: map['description'],
    );
  }
}

/// Investigation timeline entry
class InvestigationTimeline {
  final DateTime timestamp;
  final String action;
  final String performedBy;
  final String? notes;

  InvestigationTimeline({
    required this.timestamp,
    required this.action,
    required this.performedBy,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'action': action,
      'performedBy': performedBy,
      'notes': notes,
    };
  }

  factory InvestigationTimeline.fromMap(Map<String, dynamic> map) {
    return InvestigationTimeline(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? '',
      notes: map['notes'],
    );
  }
}

/// Incident Report Model
class IncidentReport {
  final String id;
  final String incidentNumber; // Format: INC-2025-000001
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String reporterId; // User who reported
  final String reporterName;
  final String reporterRole; // 'client', 'caregiver', 'admin'
  final String? bookingId; // Related booking if applicable
  final String? caregiverId; // Involved caregiver
  final String? caregiverName;
  final String? clientId; // Involved client
  final String? clientName;
  final String title;
  final String description;
  final DateTime incidentDate; // When incident occurred
  final DateTime reportedAt; // When it was reported
  final List<IncidentEvidence> evidence;
  final List<InvestigationTimeline> timeline;
  final String? assignedTo; // Admin ID assigned to investigate
  final String? assignedToName;
  final DateTime? assignedAt;
  final String? investigationNotes;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final bool actionTaken; // Whether any action was taken
  final String? actionDetails; // Details of action taken
  final bool notifyAuthorities; // Flag for severe incidents
  final List<String> tags; // For categorization/filtering

  IncidentReport({
    required this.id,
    required this.incidentNumber,
    required this.type,
    required this.severity,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.reporterRole,
    this.bookingId,
    this.caregiverId,
    this.caregiverName,
    this.clientId,
    this.clientName,
    required this.title,
    required this.description,
    required this.incidentDate,
    required this.reportedAt,
    this.evidence = const [],
    this.timeline = const [],
    this.assignedTo,
    this.assignedToName,
    this.assignedAt,
    this.investigationNotes,
    this.resolutionNotes,
    this.resolvedAt,
    this.resolvedBy,
    this.actionTaken = false,
    this.actionDetails,
    this.notifyAuthorities = false,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'incidentNumber': incidentNumber,
      'type': type.name,
      'severity': severity.name,
      'status': status.name,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterRole': reporterRole,
      'bookingId': bookingId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'clientId': clientId,
      'clientName': clientName,
      'title': title,
      'description': description,
      'incidentDate': Timestamp.fromDate(incidentDate),
      'reportedAt': Timestamp.fromDate(reportedAt),
      'evidence': evidence.map((e) => e.toMap()).toList(),
      'timeline': timeline.map((t) => t.toMap()).toList(),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'investigationNotes': investigationNotes,
      'resolutionNotes': resolutionNotes,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'actionTaken': actionTaken,
      'actionDetails': actionDetails,
      'notifyAuthorities': notifyAuthorities,
      'tags': tags,
    };
  }

  factory IncidentReport.fromMap(String id, Map<String, dynamic> map) {
    return IncidentReport(
      id: id,
      incidentNumber: map['incidentNumber'] ?? '',
      type: _parseIncidentType(map['type']),
      severity: _parseSeverity(map['severity']),
      status: _parseStatus(map['status']),
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reporterRole: map['reporterRole'] ?? '',
      bookingId: map['bookingId'],
      caregiverId: map['caregiverId'],
      caregiverName: map['caregiverName'],
      clientId: map['clientId'],
      clientName: map['clientName'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      incidentDate: (map['incidentDate'] as Timestamp).toDate(),
      reportedAt: (map['reportedAt'] as Timestamp).toDate(),
      evidence: (map['evidence'] as List<dynamic>?)
              ?.map((e) => IncidentEvidence.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: (map['timeline'] as List<dynamic>?)
              ?.map((t) => InvestigationTimeline.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      assignedAt: map['assignedAt'] != null ? (map['assignedAt'] as Timestamp).toDate() : null,
      investigationNotes: map['investigationNotes'],
      resolutionNotes: map['resolutionNotes'],
      resolvedAt: map['resolvedAt'] != null ? (map['resolvedAt'] as Timestamp).toDate() : null,
      resolvedBy: map['resolvedBy'],
      actionTaken: map['actionTaken'] ?? false,
      actionDetails: map['actionDetails'],
      notifyAuthorities: map['notifyAuthorities'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  static IncidentType _parseIncidentType(String? type) {
    switch (type) {
      case 'safetyViolation':
        return IncidentType.safetyViolation;
      case 'professionalMisconduct':
        return IncidentType.professionalMisconduct;
      case 'serviceQualityIssue':
        return IncidentType.serviceQualityIssue;
      case 'clientComplaint':
        return IncidentType.clientComplaint;
      case 'caregiverComplaint':
        return IncidentType.caregiverComplaint;
      case 'paymentDispute':
        return IncidentType.paymentDispute;
      case 'noShow':
        return IncidentType.noShow;
      case 'inappropriateBehavior':
        return IncidentType.inappropriateBehavior;
      case 'damageToProperty':
        return IncidentType.damageToProperty;
      case 'medicalIncident':
        return IncidentType.medicalIncident;
      default:
        return IncidentType.other;
    }
  }

  static IncidentSeverity _parseSeverity(String? severity) {
    switch (severity) {
      case 'low':
        return IncidentSeverity.low;
      case 'medium':
        return IncidentSeverity.medium;
      case 'high':
        return IncidentSeverity.high;
      case 'critical':
        return IncidentSeverity.critical;
      default:
        return IncidentSeverity.medium;
    }
  }

  static IncidentStatus _parseStatus(String? status) {
    switch (status) {
      case 'submitted':
        return IncidentStatus.submitted;
      case 'underReview':
        return IncidentStatus.underReview;
      case 'investigating':
        return IncidentStatus.investigating;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'dismissed':
        return IncidentStatus.dismissed;
      case 'escalated':
        return IncidentStatus.escalated;
      default:
        return IncidentStatus.submitted;
    }
  }

  IncidentReport copyWith({
    IncidentType? type,
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? title,
    String? description,
    List<IncidentEvidence>? evidence,
    List<InvestigationTimeline>? timeline,
    String? assignedTo,
    String? assignedToName,
    DateTime? assignedAt,
    String? investigationNotes,
    String? resolutionNotes,
    DateTime? resolvedAt,
    String? resolvedBy,
    bool? actionTaken,
    String? actionDetails,
    bool? notifyAuthorities,
    List<String>? tags,
  }) {
    return IncidentReport(
      id: id,
      incidentNumber: incidentNumber,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterRole: reporterRole,
      bookingId: bookingId,
      caregiverId: caregiverId,
      caregiverName: caregiverName,
      clientId: clientId,
      clientName: clientName,
      title: title ?? this.title,
      description: description ?? this.description,
      incidentDate: incidentDate,
      reportedAt: reportedAt,
      evidence: evidence ?? this.evidence,
      timeline: timeline ?? this.timeline,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedAt: assignedAt ?? this.assignedAt,
      investigationNotes: investigationNotes ?? this.investigationNotes,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      actionTaken: actionTaken ?? this.actionTaken,
      actionDetails: actionDetails ?? this.actionDetails,
      notifyAuthorities: notifyAuthorities ?? this.notifyAuthorities,
      tags: tags ?? this.tags,
    );
  }
}
