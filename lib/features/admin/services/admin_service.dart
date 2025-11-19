import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin Service for managing users, caregivers, and platform operations
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current admin user
  User? get currentAdmin => _auth.currentUser;

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // ===========================
  // STATISTICS
  // ===========================

  /// Get platform statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final verificationsSnapshot = await _firestore.collection('verification_requests').get();

      int totalUsers = usersSnapshot.size;
      int totalClients = 0;
      int totalCaregivers = 0;
      int verifiedCaregivers = 0;
      int pendingVerifications = 0;

      for (var doc in usersSnapshot.docs) {
        final role = doc.data()['role'];
        if (role == 'client') {
          totalClients++;
        } else if (role == 'caregiver') {
          totalCaregivers++;
          if (doc.data()['verificationStatus'] == 'approved') {
            verifiedCaregivers++;
          }
        }
      }

      for (var doc in verificationsSnapshot.docs) {
        if (doc.data()['status'] == 'pending') {
          pendingVerifications++;
        }
      }

      return {
        'totalUsers': totalUsers,
        'totalClients': totalClients,
        'totalCaregivers': totalCaregivers,
        'verifiedCaregivers': verifiedCaregivers,
        'pendingVerifications': pendingVerifications,
        'totalBookings': bookingsSnapshot.size,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  // ===========================
  // USER MANAGEMENT
  // ===========================

  /// Get all users with optional role filter
  Stream<List<Map<String, dynamic>>> getAllUsers({String? roleFilter}) {
    Query query = _firestore.collection('users');

    if (roleFilter != null && roleFilter != 'all') {
      query = query.where('role', isEqualTo: roleFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Get user details by ID
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  /// Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  /// Suspend/Activate user
  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Delete verification requests
      final verifications = await _firestore
          .collection('verification_requests')
          .where('caregiverId', isEqualTo: userId)
          .get();
      for (var doc in verifications.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // ===========================
  // CAREGIVER VERIFICATION
  // ===========================

  /// Get all verification requests
  Stream<List<Map<String, dynamic>>> getVerificationRequests({String? statusFilter}) {
    Query query = _firestore.collection('verification_requests');

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.orderBy('requestedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Get caregiver details with documents
  Future<Map<String, dynamic>?> getCaregiverDetails(String caregiverId) async {
    try {
      final doc = await _firestore.collection('users').doc(caregiverId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Error getting caregiver details: $e');
      return null;
    }
  }

  /// Approve caregiver verification
  Future<bool> approveVerification({
    required String requestId,
    required String caregiverId,
    String? notes,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update verification request
      final requestRef = _firestore.collection('verification_requests').doc(requestId);
      batch.update(requestRef, {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': currentAdmin?.uid,
        'notes': notes,
      });

      // Update caregiver status
      final userRef = _firestore.collection('users').doc(caregiverId);
      batch.update(userRef, {
        'verificationStatus': 'approved',
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': caregiverId,
        'type': 'verification_approved',
        'title': 'Verification Approved',
        'message': 'Congratulations! Your profile has been verified.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error approving verification: $e');
      return false;
    }
  }

  /// Reject caregiver verification
  Future<bool> rejectVerification({
    required String requestId,
    required String caregiverId,
    required String reason,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update verification request
      final requestRef = _firestore.collection('verification_requests').doc(requestId);
      batch.update(requestRef, {
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': currentAdmin?.uid,
        'rejectionReason': reason,
      });

      // Update caregiver status
      final userRef = _firestore.collection('users').doc(caregiverId);
      batch.update(userRef, {
        'verificationStatus': 'rejected',
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification
      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': caregiverId,
        'type': 'verification_rejected',
        'title': 'Verification Rejected',
        'message': 'Your verification request has been rejected. Reason: $reason',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error rejecting verification: $e');
      return false;
    }
  }

  // ===========================
  // BOOKINGS MANAGEMENT
  // ===========================

  /// Get all bookings
  Stream<List<Map<String, dynamic>>> getAllBookings({String? statusFilter}) {
    Query query = _firestore.collection('bookings');

    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }

  /// Update booking status
  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }
}
