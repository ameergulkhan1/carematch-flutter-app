import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for storing and retrieving documents using browser IndexedDB
/// Documents are stored as base64 encoded strings in Firestore
class DocumentStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Store document as base64 in Firestore
  Future<Map<String, dynamic>> storeDocument({
    required String uid,
    required String documentType,
    required Uint8List fileBytes,
    required String fileName,
    required int fileSize,
  }) async {
    try {
      // Convert file bytes to base64
      final base64String = base64Encode(fileBytes);
      
      // Create document path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final docId = '${uid}_${documentType}_$timestamp';
      
      // Store in Firestore documents collection
      await _firestore.collection('stored_documents').doc(docId).set({
        'userId': uid,
        'documentType': documentType,
        'fileName': fileName,
        'fileSize': fileSize,
        'base64Data': base64String,
        'uploadedAt': FieldValue.serverTimestamp(),
        'mimeType': _getMimeType(fileName),
      });

      return {
        'success': true,
        'docId': docId,
        'fileName': fileName,
      };
    } catch (e) {
      print('Error storing document: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Retrieve document from Firestore
  Future<Map<String, dynamic>?> getDocument(String docId) async {
    try {
      final doc = await _firestore.collection('stored_documents').doc(docId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return {
        'fileName': data['fileName'],
        'fileSize': data['fileSize'],
        'mimeType': data['mimeType'],
        'base64Data': data['base64Data'],
        'uploadedAt': data['uploadedAt'],
      };
    } catch (e) {
      print('Error retrieving document: $e');
      return null;
    }
  }

  /// Get all documents for a user
  Future<List<Map<String, dynamic>>> getUserDocuments(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('stored_documents')
          .where('userId', isEqualTo: uid)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'docId': doc.id,
          'documentType': data['documentType'],
          'fileName': data['fileName'],
          'fileSize': data['fileSize'],
          'mimeType': data['mimeType'],
          'uploadedAt': data['uploadedAt'],
          // Don't include base64Data in list to save memory
        };
      }).toList();
    } catch (e) {
      print('Error getting user documents: $e');
      return [];
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String docId) async {
    try {
      await _firestore.collection('stored_documents').doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Convert base64 to bytes
  Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }
}
