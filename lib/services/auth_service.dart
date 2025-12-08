import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/app_config.dart';
import '../models/client_user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store OTPs temporarily (in production, use a more secure method)
  final Map<String, Map<String, dynamic>> _otpStore = {};

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Generate OTP
  String _generateOTP() {
    final random = Random();
    return List.generate(AppConfig.otpLength, (_) => random.nextInt(10)).join();
  }

  // Send OTP via Email (using Firebase or custom method)
  Future<bool> sendOTPEmail(String email, String name) async {
    try {
      print('🔄 Starting OTP generation for: $email');
      final otp = _generateOTP();
      print('✓ OTP generated: $otp');
      final expiryTime = DateTime.now().add(const Duration(minutes: AppConfig.otpExpiryMinutes));

      // Store OTP in memory
      _otpStore[email] = {
        'otp': otp,
        'expiry': expiryTime,
      };
      print('✓ OTP stored in memory');

      // Also store in Firestore for persistence
      try {
        await _firestore.collection('otp_codes').doc(email).set({
          'otp': otp,
          'expiryTime': Timestamp.fromDate(expiryTime),
          'createdAt': Timestamp.now(),
        });
        print('✓ OTP stored in Firestore');
      } catch (firestoreError) {
        print('⚠️ Firestore storage failed (continuing anyway): $firestoreError');
      }

      // Send OTP via EmailJS if configured
      if (AppConfig.emailJsPublicKey.isNotEmpty) {
        print('📤 Attempting to send email via EmailJS...');
        try {
          final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'service_id': AppConfig.emailJsServiceId,
              'template_id': AppConfig.emailJsTemplateId,
              'user_id': AppConfig.emailJsPublicKey,
              'template_params': {
                'to_email': email,
                'to_name': name,
                'otp_code': otp,
                'expiry_minutes': AppConfig.otpExpiryMinutes.toString(),
                'app_name': AppConfig.appName,
              },
            }),
          );

          if (response.statusCode == 200) {
            print('✓ OTP email sent successfully to $email');
          } else {
            print('✗ EmailJS error: ${response.statusCode} - ${response.body}');
          }
        } catch (emailError) {
          print('✗ Email sending failed: $emailError');
        }
      } else {
        print('ℹ️ EmailJS not configured - email will not be sent');
      }
      
      // Always print to console for development/testing
      print('═══════════════════════════════════════');
      print('📧 OTP for $email');
      print('👤 Name: $name');
      print('🔐 Code: $otp');
      print('⏰ Valid for ${AppConfig.otpExpiryMinutes} minutes');
      print('═══════════════════════════════════════');

      return true;
    } catch (e) {
      print('❌ Error sending OTP: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String enteredOTP) async {
    try {
      // First check memory store
      if (_otpStore.containsKey(email)) {
        final otpData = _otpStore[email]!;
        final storedOTP = otpData['otp'] as String;
        final expiryTime = otpData['expiry'] as DateTime;

        if (DateTime.now().isAfter(expiryTime)) {
          _otpStore.remove(email);
          await _firestore.collection('otp_codes').doc(email).delete();
          return false;
        }

        if (storedOTP == enteredOTP) {
          _otpStore.remove(email);
          await _firestore.collection('otp_codes').doc(email).delete();
          return true;
        }
      }

      // Fallback: check Firestore
      final otpDoc = await _firestore.collection('otp_codes').doc(email).get();
      if (otpDoc.exists) {
        final data = otpDoc.data()!;
        final storedOTP = data['otp'] as String;
        final expiryTime = (data['expiryTime'] as Timestamp).toDate();

        if (DateTime.now().isAfter(expiryTime)) {
          await _firestore.collection('otp_codes').doc(email).delete();
          return false;
        }

        if (storedOTP == enteredOTP) {
          await _firestore.collection('otp_codes').doc(email).delete();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
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
          'message': 'This email is already registered as a $existingRole. Please use a different email or login as $existingRole.'
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
      await _firestore.collection('users').doc(user.uid).set(clientUser.toFirestore());

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

  // Update email verification status
  Future<void> markEmailAsVerified(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isEmailVerified': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating email verification: $e');
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
  Future<bool> updateClientProfile(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e.code)};
    } catch (e) {
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
