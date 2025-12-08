import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

class CareSession {
  final String id;
  final String bookingId;
  final String caregiverId;
  final String caregiverName;
  final String clientId;
  final String clientName;
  final DateTime scheduledDate;
  final String scheduledStartTime;
  final String scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final SessionStatus status;
  final List<String> tasks;
  final List<Map<String, dynamic>> taskCompletionLog; // Task completion records
  final List<String> notes; // Session notes
  final String? clientFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareSession({
    required this.id,
    required this.bookingId,
    required this.caregiverId,
    required this.caregiverName,
    required this.clientId,
    required this.clientName,
    required this.scheduledDate,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    this.status = SessionStatus.scheduled,
    this.tasks = const [],
    this.taskCompletionLog = const [],
    this.notes = const [],
    this.clientFeedback,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'clientId': clientId,
      'clientName': clientName,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledStartTime': scheduledStartTime,
      'scheduledEndTime': scheduledEndTime,
      'actualStartTime': actualStartTime != null 
          ? Timestamp.fromDate(actualStartTime!) 
          : null,
      'actualEndTime': actualEndTime != null 
          ? Timestamp.fromDate(actualEndTime!) 
          : null,
      'status': status.name,
      'tasks': tasks,
      'taskCompletionLog': taskCompletionLog,
      'notes': notes,
      'clientFeedback': clientFeedback,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CareSession.fromMap(String id, Map<String, dynamic> map) {
    return CareSession(
      id: id,
      bookingId: map['bookingId'] ?? '',
      caregiverId: map['caregiverId'] ?? '',
      caregiverName: map['caregiverName'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      scheduledStartTime: map['scheduledStartTime'] ?? '',
      scheduledEndTime: map['scheduledEndTime'] ?? '',
      actualStartTime: map['actualStartTime'] != null
          ? (map['actualStartTime'] as Timestamp).toDate()
          : null,
      actualEndTime: map['actualEndTime'] != null
          ? (map['actualEndTime'] as Timestamp).toDate()
          : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      tasks: List<String>.from(map['tasks'] ?? []),
      taskCompletionLog: List<Map<String, dynamic>>.from(
        (map['taskCompletionLog'] ?? []).map((item) => Map<String, dynamic>.from(item)),
      ),
      notes: List<String>.from(map['notes'] ?? []),
      clientFeedback: map['clientFeedback'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  CareSession copyWith({
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    SessionStatus? status,
    List<String>? tasks,
    List<Map<String, dynamic>>? taskCompletionLog,
    List<String>? notes,
    String? clientFeedback,
    DateTime? updatedAt,
  }) {
    return CareSession(
      id: id,
      bookingId: bookingId,
      caregiverId: caregiverId,
      caregiverName: caregiverName,
      clientId: clientId,
      clientName: clientName,
      scheduledDate: scheduledDate,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      taskCompletionLog: taskCompletionLog ?? this.taskCompletionLog,
      notes: notes ?? this.notes,
      clientFeedback: clientFeedback ?? this.clientFeedback,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate actual duration in hours
  double? get actualDurationInHours {
    if (actualStartTime == null || actualEndTime == null) return null;
    final duration = actualEndTime!.difference(actualStartTime!);
    return duration.inMinutes / 60.0;
  }

  // Check if session is overdue
  bool get isOverdue {
    if (status == SessionStatus.completed || status == SessionStatus.cancelled) {
      return false;
    }
    final now = DateTime.now();
    return now.isAfter(scheduledDate);
  }

  // Get completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    return (taskCompletionLog.length / tasks.length) * 100;
  }
}
