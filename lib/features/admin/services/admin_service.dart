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
      // Verify admin authentication first
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No authenticated user');
        return {};
      }

      // Check if user is admin
      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
        print('Error: User is not an admin');
        return {};
      }

      // Now fetch data with proper authentication
      final usersSnapshot = await _firestore.collection('users').get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      
      // Try to get verification requests, but handle permission errors gracefully
      int pendingVerifications = 0;
      try {
        final verificationsSnapshot = await _firestore
            .collection('verification_requests')
            .where('status', isEqualTo: 'pending')
            .get();
        pendingVerifications = verificationsSnapshot.size;
      } catch (e) {
        print('Error getting verification requests: $e');
        // Count from users collection as fallback
        final pendingCaregivers = usersSnapshot.docs.where((doc) => 
          doc.data()['role'] == 'caregiver' && 
          doc.data()['verificationStatus'] == 'pending'
        ).length;
        pendingVerifications = pendingCaregivers;
      }

      int totalUsers = usersSnapshot.size;
      int totalClients = 0;
      int totalCaregivers = 0;
      int verifiedCaregivers = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = data['role'];
        if (role == 'client') {
          totalClients++;
        } else if (role == 'caregiver') {
          totalCaregivers++;
          if (data['verificationStatus'] == 'approved') {
            verifiedCaregivers++;
          }
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
      return {
        'totalUsers': 0,
        'totalClients': 0,
        'totalCaregivers': 0,
        'verifiedCaregivers': 0,
        'pendingVerifications': 0,
        'totalBookings': 0,
      };
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
    try {
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
      }).handleError((error) {
        print('Error in getVerificationRequests stream: $error');
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      print('Error setting up verification requests stream: $e');
      // Return empty stream on error
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  /// Get pending caregivers from users collection (fallback method)
  /// This is used when verification_requests collection has permission issues
  Stream<List<Map<String, dynamic>>> getPendingCaregiversFromUsers({String? statusFilter}) {
    try {
      Query query = _firestore.collection('users').where('role', isEqualTo: 'caregiver');

      if (statusFilter != null && statusFilter != 'all') {
        query = query.where('verificationStatus', isEqualTo: statusFilter);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'caregiverId': doc.id,
            'status': data['verificationStatus'] ?? 'pending',
            'requestedAt': data['createdAt'],
            'fullName': data['fullName'],
            'email': data['email'],
            ...data,
          };
        }).toList();
      }).handleError((error) {
        print('Error in getPendingCaregiversFromUsers stream: $error');
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      print('Error setting up pending caregivers stream: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
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
