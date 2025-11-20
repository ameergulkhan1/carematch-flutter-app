import 'package:cloud_firestore/cloud_firestore.dart';

class AdminVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all verification requests with optional status filter
  Stream<List<Map<String, dynamic>>> getVerificationRequests({
    String? statusFilter,
  }) {
    Query query = _firestore.collection('verification_requests');

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.orderBy('requestedAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      },
    );
  }

  /// Get caregiver details by ID
  Future<Map<String, dynamic>?> getCaregiverDetails(String caregiverId) async {
    try {
      final doc = await _firestore.collection('users').doc(caregiverId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching caregiver details: $e');
      return null;
    }
  }

  /// Get document history for a caregiver
  Future<List<Map<String, dynamic>>> getDocumentHistory(String caregiverId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(caregiverId)
          .collection('document_history')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching document history: $e');
      return [];
    }
  }

  /// Approve a verification request
  Future<bool> approveVerification({
    required String requestId,
    required String caregiverId,
    required String adminId,
    required String adminNotes,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update verification request
      final requestRef = _firestore.collection('verification_requests').doc(requestId);
      batch.update(requestRef, {
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'adminNotes': adminNotes,
      });

      // Update caregiver user status
      final userRef = _firestore.collection('users').doc(caregiverId);
      batch.update(userRef, {
        'verificationStatus': 'approved',
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for caregiver
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': caregiverId,
        'type': 'verification_approved',
        'title': '✅ Verification Approved',
        'message': 'Congratulations! Your caregiver profile has been approved. You can now start receiving bookings.',
        'adminNotes': adminNotes,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      final auditLogRef = _firestore.collection('audit_logs').doc();
      batch.set(auditLogRef, {
        'action': 'verification_approved',
        'adminId': adminId,
        'targetUserId': caregiverId,
        'requestId': requestId,
        'adminNotes': adminNotes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error approving verification: $e');
      return false;
    }
  }

  /// Reject a verification request
  Future<bool> rejectVerification({
    required String requestId,
    required String caregiverId,
    required String adminId,
    required String rejectionReason,
    required List<String> rejectedDocuments,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update verification request
      final requestRef = _firestore.collection('verification_requests').doc(requestId);
      batch.update(requestRef, {
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
        'rejectedDocuments': rejectedDocuments,
      });

      // Update caregiver user status
      final userRef = _firestore.collection('users').doc(caregiverId);
      batch.update(userRef, {
        'verificationStatus': 'rejected',
        'isVerified': false,
        'documentsSubmitted': false, // Allow resubmission
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for caregiver
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': caregiverId,
        'type': 'verification_rejected',
        'title': '❌ Verification Rejected',
        'message': 'Your verification request needs attention. Please review the feedback and resubmit.',
        'rejectionReason': rejectionReason,
        'rejectedDocuments': rejectedDocuments,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      final auditLogRef = _firestore.collection('audit_logs').doc();
      batch.set(auditLogRef, {
        'action': 'verification_rejected',
        'adminId': adminId,
        'targetUserId': caregiverId,
        'requestId': requestId,
        'rejectionReason': rejectionReason,
        'rejectedDocuments': rejectedDocuments,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error rejecting verification: $e');
      return false;
    }
  }

  /// Request document revision
  Future<bool> requestRevision({
    required String requestId,
    required String caregiverId,
    required String adminId,
    required String revisionNotes,
    required List<String> documentsToRevise,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update verification request
      final requestRef = _firestore.collection('verification_requests').doc(requestId);
      batch.update(requestRef, {
        'status': 'revision_requested',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'revisionNotes': revisionNotes,
        'documentsToRevise': documentsToRevise,
      });

      // Update caregiver user status
      final userRef = _firestore.collection('users').doc(caregiverId);
      batch.update(userRef, {
        'verificationStatus': 'revision_requested',
        'documentsSubmitted': false, // Allow resubmission
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for caregiver
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': caregiverId,
        'type': 'revision_requested',
        'title': '📝 Document Revision Requested',
        'message': 'Please revise and resubmit the following documents.',
        'revisionNotes': revisionNotes,
        'documentsToRevise': documentsToRevise,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      final auditLogRef = _firestore.collection('audit_logs').doc();
      batch.set(auditLogRef, {
        'action': 'verification_revision_requested',
        'adminId': adminId,
        'targetUserId': caregiverId,
        'requestId': requestId,
        'revisionNotes': revisionNotes,
        'documentsToRevise': documentsToRevise,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error requesting revision: $e');
      return false;
    }
  }

  /// Get verification statistics
  Future<Map<String, int>> getVerificationStats() async {
    try {
      final snapshot = await _firestore.collection('verification_requests').get();
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int revisionRequested = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'revision_requested':
            revisionRequested++;
            break;
        }
      }

      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'revision_requested': revisionRequested,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'revision_requested': 0,
        'total': 0,
      };
    }
  }
}
