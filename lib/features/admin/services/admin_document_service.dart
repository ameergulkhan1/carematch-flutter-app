import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:html' as html;

/// Admin Document Service for viewing and downloading caregiver documents
class AdminDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all documents for a specific user/caregiver
  Future<List<Map<String, dynamic>>> getUserDocuments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('stored_documents')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'documentType': data['documentType'] ?? '',
          'fileName': data['fileName'] ?? '',
          'fileSize': data['fileSize'] ?? 0,
          'uploadedAt': data['uploadedAt'],
          'userId': data['userId'],
          'mimeType': data['mimeType'] ?? 'application/octet-stream',
          // Don't include base64Data in list view for performance
        };
      }).toList();
    } catch (e) {
      print('Error getting user documents: $e');
      return [];
    }
  }

  /// Get all documents across all users (for admin overview)
  Stream<List<Map<String, dynamic>>> getAllDocuments() {
    return _firestore
        .collection('stored_documents')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'documentType': data['documentType'] ?? '',
          'fileName': data['fileName'] ?? '',
          'fileSize': data['fileSize'] ?? 0,
          'uploadedAt': data['uploadedAt'],
          'userId': data['userId'],
          'mimeType': data['mimeType'] ?? 'application/octet-stream',
        };
      }).toList();
    });
  }

  /// Get document details including base64 data
  Future<Map<String, dynamic>?> getDocumentDetails(String documentId) async {
    try {
      final doc = await _firestore.collection('stored_documents').doc(documentId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Error getting document details: $e');
      return null;
    }
  }

  /// Download document to user's computer
  Future<bool> downloadDocument(String documentId) async {
    try {
      final doc = await _firestore.collection('stored_documents').doc(documentId).get();
      if (!doc.exists) {
        print('Document not found');
        return false;
      }

      final data = doc.data()!;
      final base64Data = data['base64Data'] as String;
      final fileName = data['fileName'] as String;
      final mimeType = data['mimeType'] as String? ?? 'application/octet-stream';

      // Decode base64 to bytes
      final bytes = base64Decode(base64Data);

      // Create blob and download link
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);

      print('Document downloaded successfully: $fileName');
      return true;
    } catch (e) {
      print('Error downloading document: $e');
      return false;
    }
  }

  /// Download all documents for a specific user as a ZIP (simplified version)
  Future<bool> downloadUserDocuments(String userId) async {
    try {
      final documents = await getUserDocuments(userId);
      
      // Download each document individually
      for (var docMeta in documents) {
        await downloadDocument(docMeta['id']);
        // Add small delay between downloads
        await Future.delayed(Duration(milliseconds: 500));
      }

      return true;
    } catch (e) {
      print('Error downloading user documents: $e');
      return false;
    }
  }

  /// Get document statistics
  Future<Map<String, dynamic>> getDocumentStatistics() async {
    try {
      final snapshot = await _firestore.collection('stored_documents').get();
      
      int totalDocuments = snapshot.size;
      int totalSize = 0;
      Map<String, int> documentsByType = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final fileSize = data['fileSize'] as int? ?? 0;
        final docType = data['documentType'] as String? ?? 'unknown';

        totalSize += fileSize;
        documentsByType[docType] = (documentsByType[docType] ?? 0) + 1;
      }

      return {
        'totalDocuments': totalDocuments,
        'totalSize': totalSize,
        'documentsByType': documentsByType,
      };
    } catch (e) {
      print('Error getting document statistics: $e');
      return {};
    }
  }

  /// Delete document (admin only)
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('stored_documents').doc(documentId).delete();
      print('Document deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  /// View document in new tab/window
  Future<bool> viewDocument(String documentId) async {
    try {
      final doc = await _firestore.collection('stored_documents').doc(documentId).get();
      if (!doc.exists) {
        print('Document not found');
        return false;
      }

      final data = doc.data()!;
      final base64Data = data['base64Data'] as String;
      final mimeType = data['mimeType'] as String? ?? 'application/octet-stream';

      // Decode base64 to bytes
      final bytes = base64Decode(base64Data);

      // Create blob URL
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Open in new window
      html.window.open(url, '_blank');

      // Clean up after a delay
      Future.delayed(Duration(seconds: 5), () {
        html.Url.revokeObjectUrl(url);
      });

      return true;
    } catch (e) {
      print('Error viewing document: $e');
      return false;
    }
  }

  /// Get documents by type
  Future<List<Map<String, dynamic>>> getDocumentsByType(String documentType) async {
    try {
      final snapshot = await _firestore
          .collection('stored_documents')
          .where('documentType', isEqualTo: documentType)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'documentType': data['documentType'] ?? '',
          'fileName': data['fileName'] ?? '',
          'fileSize': data['fileSize'] ?? 0,
          'uploadedAt': data['uploadedAt'],
          'userId': data['userId'],
          'mimeType': data['mimeType'] ?? 'application/octet-stream',
        };
      }).toList();
    } catch (e) {
      print('Error getting documents by type: $e');
      return [];
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get document type label
  String getDocumentTypeLabel(String documentType) {
    switch (documentType) {
      case 'id_proof':
        return 'ID Proof';
      case 'address_proof':
        return 'Address Proof';
      case 'certifications':
        return 'Certifications';
      case 'background_check':
        return 'Background Check';
      default:
        return documentType;
    }
  }
}
