import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/care_session_model.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new care session
  Future<String?> createSession(CareSession session) async {
    try {
      final docRef = await _firestore.collection('care_sessions').add(session.toMap());
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating session: $e');
      return null;
    }
  }

  /// Get sessions for a caregiver
  Stream<List<CareSession>> getCaregiverSessions(String caregiverId, {SessionStatus? statusFilter}) {
    Query query = _firestore
        .collection('care_sessions')
        .where('caregiverId', isEqualTo: caregiverId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CareSession.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Get sessions for a client
  Stream<List<CareSession>> getClientSessions(String clientId, {SessionStatus? statusFilter}) {
    Query query = _firestore
        .collection('care_sessions')
        .where('clientId', isEqualTo: clientId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CareSession.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Get sessions for a booking
  Stream<List<CareSession>> getBookingSessions(String bookingId) {
    return _firestore
        .collection('care_sessions')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CareSession.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get a single session
  Future<CareSession?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('care_sessions').doc(sessionId).get();
      if (doc.exists) {
        return CareSession.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting session: $e');
      return null;
    }
  }

  /// Start a new session
  Future<String?> startSession({
    required String bookingId,
    required String caregiverId,
    required String caregiverName,
    required String clientId,
    required String clientName,
    required DateTime scheduledDate,
    required String scheduledStartTime,
    required String scheduledEndTime,
    required List<String> tasks,
  }) async {
    try {
      final now = DateTime.now();
      final session = CareSession(
        id: '',
        bookingId: bookingId,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        clientId: clientId,
        clientName: clientName,
        scheduledDate: scheduledDate,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        status: SessionStatus.inProgress,
        tasks: tasks,
        taskCompletionLog: [],
        notes: [],
        actualStartTime: now,
        actualEndTime: null,
        clientFeedback: null,
        createdAt: now,
        updatedAt: now,
      );
      
      final docRef = await _firestore.collection('care_sessions').add(session.toMap());
      return docRef.id;
    } catch (e) {
      // ignore: avoid_print
      print('Error starting session: $e');
      return null;
    }
  }

  /// Complete a session
  Future<bool> completeSession(String sessionId) async {
    try {
      await _firestore.collection('care_sessions').doc(sessionId).update({
        'status': SessionStatus.completed.name,
        'actualEndTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error completing session: $e');
      return false;
    }
  }

  /// Add a task completion log entry
  Future<bool> logTaskCompletion(String sessionId, String taskName, {String? notes}) async {
    try {
      final logEntry = {
        'task': taskName,
        'completedAt': FieldValue.serverTimestamp(),
        'notes': notes ?? '',
      };

      await _firestore.collection('care_sessions').doc(sessionId).update({
        'taskCompletionLog': FieldValue.arrayUnion([logEntry]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error logging task completion: $e');
      return false;
    }
  }

  /// Add a note to the session
  Future<bool> addSessionNote(String sessionId, String note) async {
    try {
      await _firestore.collection('care_sessions').doc(sessionId).update({
        'notes': FieldValue.arrayUnion([note]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding session note: $e');
      return false;
    }
  }

  /// Add notes to the session (alias for compatibility)
  Future<bool> addSessionNotes(String sessionId, String note) async {
    return addSessionNote(sessionId, note);
  }

  /// Add client feedback
  Future<bool> addClientFeedback(String sessionId, String feedback) async {
    try {
      await _firestore.collection('care_sessions').doc(sessionId).update({
        'clientFeedback': feedback,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding client feedback: $e');
      return false;
    }
  }

  /// Cancel a session
  Future<bool> cancelSession(String sessionId, String reason) async {
    try {
      await _firestore.collection('care_sessions').doc(sessionId).update({
        'status': SessionStatus.cancelled.name,
        'notes': FieldValue.arrayUnion(['Cancelled: $reason']),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error cancelling session: $e');
      return false;
    }
  }

  /// Get today's sessions for a caregiver
  Stream<List<CareSession>> getTodaySessions(String caregiverId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('care_sessions')
        .where('caregiverId', isEqualTo: caregiverId)
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CareSession.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get upcoming sessions for a caregiver
  Stream<List<CareSession>> getUpcomingSessions(String caregiverId, {int limit = 10}) {
    final now = DateTime.now();

    return _firestore
        .collection('care_sessions')
        .where('caregiverId', isEqualTo: caregiverId)
        .where('scheduledDate', isGreaterThan: Timestamp.fromDate(now))
        .where('status', isEqualTo: SessionStatus.scheduled.name)
        .orderBy('scheduledDate')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CareSession.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
