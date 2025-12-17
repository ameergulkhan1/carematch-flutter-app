import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../models/caregiver_user_model.dart';
import 'document_storage_service.dart';
import 'auth_service.dart';

class CaregiverService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DocumentStorageService _documentStorage = DocumentStorageService();
  final AuthService _authService = AuthService();

  /// Register new caregiver (Step 1 & 2: Auth + Basic Info)
  Future<Map<String, dynamic>> registerCaregiver({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? phoneCountryCode,
    String? phoneDialCode,
    required DateTime dateOfBirth,
    required String address,
    required String city,
    required String state,
    required String zipCode,
  }) async {
    try {
      // Check if email already exists with a different role
      final existingRole = await _authService.checkEmailRole(email);
      if (existingRole != null && existingRole != 'caregiver') {
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

      // Create caregiver document in Firestore
      final caregiverUser = CaregiverUser(
        uid: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        phoneCountryCode: phoneCountryCode,
        phoneDialCode: phoneDialCode,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        verificationStatus: 'pending',
        isEmailVerified: false,
        documentsSubmitted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(caregiverUser.toFirestore());

      // Send verification email automatically
      await user.sendEmailVerification();
      print('✅ Verification email sent to $email');

      return {
        'success': true,
        'uid': user.uid,
        'email': email,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  /// Update professional information (Step 4: After email verification)
  Future<bool> updateProfessionalInfo({
    required String uid,
    required String yearsOfExperience,
    required List<String> specializations,
    String? bio,
    List<String>? certifications,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'yearsOfExperience': yearsOfExperience,
        'specializations': specializations,
        'bio': bio,
        'certifications': certifications ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating professional info: $e');
      return false;
    }
  }

  /// Upload document to local storage
  Future<Map<String, dynamic>> uploadDocument({
    required String uid,
    required String documentType,
    required PlatformFile file,
  }) async {
    try {
      // Validate file
      if (file.bytes == null && file.path == null) {
        return {'success': false, 'message': 'Invalid file'};
      }

      // Validate file type (PDF, JPG, PNG)
      final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
      final fileExtension = file.extension?.toLowerCase() ?? '';
      if (!allowedExtensions.contains(fileExtension)) {
        return {
          'success': false,
          'message': 'Only PDF, JPG, and PNG files are allowed'
        };
      }

      // Validate file size (max 5MB)
      const maxSize = 5 * 1024 * 1024; // 5MB
      final fileSize = file.size;
      if (fileSize > maxSize) {
        return {'success': false, 'message': 'File size must be less than 5MB'};
      }

      // For web, we'll store the file in Firestore as base64
      // This allows viewing from any device with proper authentication

      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null) {
        return {'success': false, 'message': 'Could not read file data'};
      }

      // Store document with base64 encoding
      final storageResult = await _documentStorage.storeDocument(
        uid: uid,
        documentType: documentType,
        fileBytes: fileBytes,
        fileName: file.name,
        fileSize: fileSize,
      );

      if (storageResult['success'] != true) {
        return {
          'success': false,
          'message': storageResult['message'] ?? 'Failed to store document'
        };
      }

      final docId = storageResult['docId'];

      print('✓ Document stored in Firestore: $docId');

      // Update user's documents map with docId
      await _firestore.collection('users').doc(uid).update({
        'documents.$documentType': docId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log document upload
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('document_history')
          .add({
        'documentType': documentType,
        'fileName': file.name,
        'fileSize': fileSize,
        'docId': docId,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✓ Document ID stored in user profile: $documentType -> $docId');

      return {
        'success': true,
        'docId': docId,
        'message': 'Document uploaded successfully'
      };
    } catch (e) {
      print('Error uploading document: $e');
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  /// Mark documents as submitted
  Future<bool> submitDocuments(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'documentsSubmitted': true,
        'verificationStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create verification request for admin
      await _firestore.collection('verification_requests').add({
        'caregiverId': uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'reviewedBy': null,
        'reviewedAt': null,
        'notes': null,
      });

      print('✓ Documents submitted for verification');
      return true;
    } catch (e) {
      print('Error submitting documents: $e');
      return false;
    }
  }

  /// Get caregiver profile
  Future<CaregiverUser?> getCaregiverProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return CaregiverUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting caregiver profile: $e');
      return null;
    }
  }

  /// Delete document from local storage and Firestore
  Future<bool> deleteDocument({
    required String uid,
    required String documentType,
  }) async {
    try {
      // Get document path from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final documents =
          Map<String, String>.from(userDoc.data()?['documents'] ?? {});

      if (!documents.containsKey(documentType)) {
        return false;
      }

      // For web compatibility, we only remove metadata from Firestore
      // In production with a backend, you'd call an API to delete the actual file

      // Remove from Firestore
      await _firestore.collection('users').doc(uid).update({
        'documents.$documentType': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Registration failed. Please try again.';
    }
  }
}
