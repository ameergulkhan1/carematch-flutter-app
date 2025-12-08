import 'package:cloud_firestore/cloud_firestore.dart';

enum CareType {
  childcare,
  elderlyCare,
  specialNeeds,
  companionship,
  medicalCare,
  dementiaCare,
}

enum ScheduleFrequency {
  oneTime,
  daily,
  weekly,
  biWeekly,
  monthly,
}

class CarePlan {
  final String id;
  final String clientId;
  final String clientName;
  final CareType careType;
  final String description;
  final int hoursPerSession;
  final ScheduleFrequency frequency;
  final List<String> tasks;
  final Map<String, dynamic> preferences;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> specificDays; // For weekly/biweekly schedules
  final String? preferredStartTime;
  final String? preferredEndTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CarePlan({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.careType,
    required this.description,
    required this.hoursPerSession,
    required this.frequency,
    required this.tasks,
    required this.preferences,
    required this.startDate,
    this.endDate,
    this.specificDays = const [],
    this.preferredStartTime,
    this.preferredEndTime,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'careType': careType.name,
      'description': description,
      'hoursPerSession': hoursPerSession,
      'frequency': frequency.name,
      'tasks': tasks,
      'preferences': preferences,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'specificDays': specificDays,
      'preferredStartTime': preferredStartTime,
      'preferredEndTime': preferredEndTime,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CarePlan.fromMap(String id, Map<String, dynamic> map) {
    return CarePlan(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      careType: CareType.values.firstWhere(
        (e) => e.name == map['careType'],
        orElse: () => CareType.companionship,
      ),
      description: map['description'] ?? '',
      hoursPerSession: map['hoursPerSession'] ?? 0,
      frequency: ScheduleFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => ScheduleFrequency.oneTime,
      ),
      tasks: List<String>.from(map['tasks'] ?? []),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      specificDays: List<String>.from(map['specificDays'] ?? []),
      preferredStartTime: map['preferredStartTime'],
      preferredEndTime: map['preferredEndTime'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  CarePlan copyWith({
    String? clientId,
    String? clientName,
    CareType? careType,
    String? description,
    int? hoursPerSession,
    ScheduleFrequency? frequency,
    List<String>? tasks,
    Map<String, dynamic>? preferences,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? specificDays,
    String? preferredStartTime,
    String? preferredEndTime,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return CarePlan(
      id: id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      careType: careType ?? this.careType,
      description: description ?? this.description,
      hoursPerSession: hoursPerSession ?? this.hoursPerSession,
      frequency: frequency ?? this.frequency,
      tasks: tasks ?? this.tasks,
      preferences: preferences ?? this.preferences,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      specificDays: specificDays ?? this.specificDays,
      preferredStartTime: preferredStartTime ?? this.preferredStartTime,
      preferredEndTime: preferredEndTime ?? this.preferredEndTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get careTypeLabel {
    switch (careType) {
      case CareType.childcare:
        return 'Childcare';
      case CareType.elderlyCare:
        return 'Elderly Care';
      case CareType.specialNeeds:
        return 'Special Needs Care';
      case CareType.companionship:
        return 'Companionship';
      case CareType.medicalCare:
        return 'Medical Care';
      case CareType.dementiaCare:
        return 'Dementia Care';
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case ScheduleFrequency.oneTime:
        return 'One-time';
      case ScheduleFrequency.daily:
        return 'Daily';
      case ScheduleFrequency.weekly:
        return 'Weekly';
      case ScheduleFrequency.biWeekly:
        return 'Bi-weekly';
      case ScheduleFrequency.monthly:
        return 'Monthly';
    }
  }
}
