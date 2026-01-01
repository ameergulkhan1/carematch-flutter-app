import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/entities/auth_credentials.dart';

/// Remote data source for authentication
/// All Firebase Auth and Firestore operations happen here
/// Throws exceptions on error (converted to Failures in repository)
abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  Future<ClientUserModel> signInWithEmailAndPassword(
      SignInCredentials credentials);

  /// Register a new client
  Future<ClientUserModel> registerClient(ClientSignUpCredentials credentials);

  /// Register a new caregiver
  Future<CaregiverUserModel> registerCaregiver(
      CaregiverSignUpCredentials credentials);

  /// Sign out the current user
  Future<void> signOut();

  /// Get current Firebase user
  User? getCurrentFirebaseUser();

  /// Get current user data from Firestore
  Future<dynamic> getCurrentUserData(String uid);

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Verify email address
  Future<void> verifyEmail();

  /// Check if email is verified
  Future<bool> isEmailVerified();

  /// Update user profile in Firestore
  Future<dynamic> updateUserProfile(String uid, Map<String, dynamic> updates);

  /// Delete user account
  Future<void> deleteAccount(String uid);

  /// Re-authenticate user
  Future<void> reauthenticate(String password);

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<ClientUserModel> signInWithEmailAndPassword(
    SignInCredentials credentials,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      if (userCredential.user == null) {
        throw AuthenticationException.userNotFound();
      }

      // Get user data from Firestore
      final userData = await getCurrentUserData(userCredential.user!.uid);

      if (userData == null) {
        throw ServerException.notFound();
      }

      // Determine user type and return appropriate model
      final role = userData['role'] as String?;
      if (role == 'client') {
        final doc = await _firestore
            .collection('clients')
            .doc(userCredential.user!.uid)
            .get();
        return ClientUserModel.fromFirestore(doc);
      } else {
        throw AuthenticationException.invalidCredentials();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException || e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ClientUserModel> registerClient(
      ClientSignUpCredentials credentials) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      if (userCredential.user == null) {
        throw const ServerException(message: 'Failed to create user');
      }

      final uid = userCredential.user!.uid;
      final now = DateTime.now();

      // Create client model
      final clientModel = ClientUserModel(
        uid: uid,
        email: credentials.email,
        fullName: credentials.fullName,
        phoneNumber: credentials.phoneNumber,
        phoneCountryCode: credentials.phoneCountryCode,
        phoneDialCode: credentials.phoneDialCode,
        isEmailVerified: false,
        createdAt: now,
        updatedAt: now,
        address: credentials.address,
        city: credentials.city,
        state: credentials.state,
        zipCode: credentials.zipCode,
      );

      // Save to Firestore
      await _firestore
          .collection('clients')
          .doc(uid)
          .set(clientModel.toFirestore());

      return clientModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException || e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CaregiverUserModel> registerCaregiver(
    CaregiverSignUpCredentials credentials,
  ) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      if (userCredential.user == null) {
        throw const ServerException(message: 'Failed to create user');
      }

      final uid = userCredential.user!.uid;
      final now = DateTime.now();

      // Create caregiver model
      final caregiverModel = CaregiverUserModel(
        uid: uid,
        email: credentials.email,
        fullName: credentials.fullName,
        phoneNumber: credentials.phoneNumber,
        phoneCountryCode: credentials.phoneCountryCode,
        phoneDialCode: credentials.phoneDialCode,
        isEmailVerified: false,
        createdAt: now,
        updatedAt: now,
        dateOfBirth: credentials.dateOfBirth,
        address: credentials.address,
        city: credentials.city,
        state: credentials.state,
        zipCode: credentials.zipCode,
        yearsOfExperience: credentials.yearsOfExperience,
        specializations: credentials.specializations,
        bio: credentials.bio,
        verificationStatus: 'pending',
        documentsSubmitted: false,
      );

      // Save to Firestore
      await _firestore
          .collection('caregivers')
          .doc(uid)
          .set(caregiverModel.toFirestore());

      return caregiverModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException || e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(message: 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  @override
  Future<dynamic> getCurrentUserData(String uid) async {
    try {
      // Try clients collection first
      final clientDoc = await _firestore.collection('clients').doc(uid).get();
      if (clientDoc.exists) {
        return clientDoc.data();
      }

      // Try caregivers collection
      final caregiverDoc =
          await _firestore.collection('caregivers').doc(uid).get();
      if (caregiverDoc.exists) {
        return caregiverDoc.data();
      }

      return null;
    } catch (e) {
      throw ServerException(
          message: 'Failed to get user data: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(
          message: 'Failed to send reset email: ${e.toString()}');
    }
  }

  @override
  Future<void> verifyEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthenticationException.unauthenticated();
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw ServerException(
          message: 'Failed to send verification email: ${e.toString()}');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthenticationException.unauthenticated();
    }
    await user.reload();
    return user.emailVerified;
  }

  @override
  Future<dynamic> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      // Add updatedAt timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();

      // Try clients collection first
      final clientDoc = await _firestore.collection('clients').doc(uid).get();
      if (clientDoc.exists) {
        await _firestore.collection('clients').doc(uid).update(updates);
        final updatedDoc =
            await _firestore.collection('clients').doc(uid).get();
        return updatedDoc.data();
      }

      // Try caregivers collection
      final caregiverDoc =
          await _firestore.collection('caregivers').doc(uid).get();
      if (caregiverDoc.exists) {
        await _firestore.collection('caregivers').doc(uid).update(updates);
        final updatedDoc =
            await _firestore.collection('caregivers').doc(uid).get();
        return updatedDoc.data();
      }

      throw ServerException.notFound();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
          message: 'Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount(String uid) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.uid != uid) {
        throw AuthenticationException.unauthenticated();
      }

      // Delete user data from Firestore
      final clientDoc = await _firestore.collection('clients').doc(uid).get();
      if (clientDoc.exists) {
        await _firestore.collection('clients').doc(uid).delete();
      }

      final caregiverDoc =
          await _firestore.collection('caregivers').doc(uid).get();
      if (caregiverDoc.exists) {
        await _firestore.collection('caregivers').doc(uid).delete();
      }

      // Delete Firebase Auth user
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw ServerException(
          message: 'Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Future<void> reauthenticate(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw AuthenticationException.unauthenticated();
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw ServerException(
          message: 'Failed to reauthenticate: ${e.toString()}');
    }
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Helper methods

  AuthenticationException _handleFirebaseAuthException(
      FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
        return AuthenticationException.invalidCredentials();
      case 'email-already-in-use':
        return AuthenticationException.emailAlreadyInUse();
      case 'weak-password':
        return AuthenticationException.weakPassword();
      case 'user-disabled':
        return AuthenticationException.accountDisabled();
      case 'too-many-requests':
        return AuthenticationException.tooManyRequests();
      case 'network-request-failed':
        return const AuthenticationException(message: 'Network error');
      case 'requires-recent-login':
        return const AuthenticationException(message: 'Please sign in again');
      default:
        return AuthenticationException(
            message: e.message ?? 'Authentication failed');
    }
  }
}
