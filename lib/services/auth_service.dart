import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send email verification link (replaces OTP system)
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return false;
      }

      if (user.emailVerified) {
        print('ℹ️ Email already verified');
        return true;
      }

      await user.sendEmailVerification();
      print('✅ Verification email sent to ${user.email}');
      return true;
    } catch (e) {
      print('❌ Error sending verification email: $e');
      return false;
    }
  }

  // Check if current user's email is verified
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      print('❌ Error checking email verification: $e');
      return false;
    }
  }

  // Mark email as verified in Firestore (called after Firebase verification)
  Future<void> markEmailAsVerified(String uid) async {
    try {
      // Update in users collection
      await _firestore.collection('users').doc(uid).update({
        'isEmailVerified': true,
      });

      // Also try clients and caregivers collections
      final clientDoc = await _firestore.collection('clients').doc(uid).get();
      if (clientDoc.exists) {
        await _firestore.collection('clients').doc(uid).update({
          'isEmailVerified': true,
        });
      }

      final caregiverDoc =
          await _firestore.collection('caregivers').doc(uid).get();
      if (caregiverDoc.exists) {
        await _firestore.collection('caregivers').doc(uid).update({
          'isEmailVerified': true,
        });
      }

      print('✅ Email verification status updated in Firestore');
    } catch (e) {
      print('❌ Error updating verification status: $e');
    }
  }

  // Check if email exists with different role
  Future<String?> checkEmailRole(String email) async {
    try {
      // Query Firestore for existing user with this email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error checking email role: $e');
      return null;
    }
  }

  // Register new client user
  Future<Map<String, dynamic>> registerClient({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    try {
      // Check if email already exists with a different role
      final existingRole = await checkEmailRole(email);
      if (existingRole != null && existingRole != 'client') {
        return {
          'success': false,
          'message':
              'This email is already registered as a $existingRole. Please use a different email or login as $existingRole.'
        };
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Failed to create user'};
      }

      // Create ClientUser object
      final clientUser = ClientUser(
        uid: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(clientUser.toFirestore());

      // Send verification email automatically
      await user.sendEmailVerification();
      print('✅ Verification email sent to $email');

      return {'success': true, 'uid': user.uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for email: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        print('❌ User credential is null');
        return {'success': false, 'message': 'Sign in failed'};
      }

      print('✅ Firebase authentication successful for UID: ${user.uid}');

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('❌ User document not found in Firestore for UID: ${user.uid}');
        return {'success': false, 'message': 'User profile not found'};
      }

      // Get user role and verification status from Firestore document
      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] ?? 'client';
      final verificationStatus = userData['verificationStatus'];

      print('✅ User role: $role');
      print('✅ Verification status: $verificationStatus');
      print('✅ Login successful for: $email');

      return {
        'success': true,
        'uid': user.uid,
        'role': role,
        'verificationStatus': verificationStatus,
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      return {'success': false, 'message': _getFirebaseErrorMessage(e.code)};
    } catch (e) {
      print('❌ Unexpected error during sign in: $e');
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Get client user data
  Future<ClientUser?> getClientUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return ClientUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting client user: $e');
      return null;
    }
  }

  // Update client profile
  Future<bool> updateClientProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Send password reset email (using Firebase's native method)
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      print('🔄 AuthService: Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email);

      print('✅ Password reset email sent successfully');
      return {
        'success': true,
        'message': 'Password reset link sent to your email'
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase error: ${e.code}');
      return {'success': false, 'message': _getFirebaseErrorMessage(e.code)};
    } catch (e) {
      print('❌ Error sending reset email: $e');
      return {'success': false, 'message': 'Failed to send reset email'};
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user-friendly error messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
