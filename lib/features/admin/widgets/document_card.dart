import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_document_service.dart';

class DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final bool showUserInfo;

  const DocumentCard({
    super.key,
    required this.document,
    this.showUserInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final documentService = AdminDocumentService();
    final docType = document['documentType'] ?? 'unknown';
    final fileName = document['fileName'] ?? 'Unknown';
    final fileSize = document['fileSize'] ?? 0;
    final uploadedAt = document['uploadedAt'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Type Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDocTypeColor(docType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocTypeIcon(docType),
                    color: _getDocTypeColor(docType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentService.getDocumentTypeLabel(docType),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (showUserInfo && document['userId'] != null)
                        Text(
                          'User: ${document['userId']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // File Name
            Text(
              fileName,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // File Size and Date
            Row(
              children: [
                Icon(Icons.insert_drive_file, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  documentService.formatFileSize(fileSize),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  _formatDate(uploadedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _viewDocument(context, documentService),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () => _downloadDocument(context, documentService),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () => _deleteDocument(context, documentService),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDocTypeColor(String docType) {
    switch (docType) {
      case 'id_proof':
        return Colors.blue;
      case 'address_proof':
        return Colors.green;
      case 'certifications':
        return Colors.orange;
      case 'background_check':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocTypeIcon(String docType) {
    switch (docType) {
      case 'id_proof':
        return Icons.badge;
      case 'address_proof':
        return Icons.home;
      case 'certifications':
        return Icons.card_membership;
      case 'background_check':
        return Icons.verified_user;
      default:
        return Icons.description;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  Future<void> _viewDocument(BuildContext context, AdminDocumentService documentService) async {
    final success = await documentService.viewDocument(document['id']);
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to view document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadDocument(BuildContext context, AdminDocumentService documentService) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading...')),
    );
    
    final success = await documentService.downloadDocument(document['id']);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Document downloaded successfully' : 'Failed to download document'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDocument(BuildContext context, AdminDocumentService documentService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await documentService.deleteDocument(document['id']);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Document deleted successfully' : 'Failed to delete document'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
