import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_topbar.dart';
import '../widgets/document_card.dart';
import '../services/admin_service.dart';
import '../services/admin_document_service.dart';
import '../admin_routes.dart';

class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  final _adminService = AdminService();
  final _documentService = AdminDocumentService();
  String _selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(currentRoute: AdminRoutes.adminVerifications),
          Expanded(
            child: Column(
              children: [
                AdminTopbar(
                  title: 'Verification Requests',
                  onRefresh: () => setState(() {}),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(),
                        const SizedBox(height: 24),
                        Expanded(child: _buildVerificationsList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.filter_list),
            const SizedBox(width: 12),
            const Text(
              'Filter by Status:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Requests')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getPendingCaregiversFromUsers(
        statusFilter: _selectedFilter == 'all' ? null : _selectedFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading verifications: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No verification requests found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildVerificationCard(request);
          },
        );
      },
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
        ),
        title: Text(
          request['caregiverName'] ?? 'Unknown Caregiver',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Requested: ${_formatDate(request['requestedAt'])} • Status: $status',
        ),
        trailing: _buildStatusBadge(status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequestDetails(request),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildDocumentsSection(request['caregiverId']),
                const SizedBox(height: 16),
                if (status == 'pending') _buildActionButtons(request),
                if (status == 'approved') _buildApprovedInfo(request),
                if (status == 'rejected') _buildRejectedInfo(request),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(Map<String, dynamic> request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caregiver Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Email', request['caregiverEmail'] ?? 'N/A'),
        _buildDetailRow('Caregiver ID', request['caregiverId'] ?? 'N/A'),
        if (request['notes'] != null)
          _buildDetailRow('Notes', request['notes']),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(String? caregiverId) {
    if (caregiverId == null) {
      return const Text('No caregiver ID available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Documents',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _documentService.getUserDocuments(caregiverId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final documents = snapshot.data ?? [];

            if (documents.isEmpty) {
              return const Text('No documents uploaded');
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: documents.map((doc) {
                return SizedBox(
                  width: 280,
                  child: DocumentCard(document: doc),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> request) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => _rejectVerification(request),
          icon: const Icon(Icons.close),
          label: const Text('Reject'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _approveVerification(request),
          icon: const Icon(Icons.check),
          label: const Text('Approve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedInfo(Map<String, dynamic> request) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Approved',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Reviewed on: ${_formatDate(request['reviewedAt'])}'),
          if (request['notes'] != null)
            Text('Notes: ${request['notes']}'),
        ],
      ),
    );
  }

  Widget _buildRejectedInfo(Map<String, dynamic> request) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Rejected',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Reviewed on: ${_formatDate(request['reviewedAt'])}'),
          if (request['rejectionReason'] != null)
            Text('Reason: ${request['rejectionReason']}'),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  Future<void> _approveVerification(Map<String, dynamic> request) async {
    final notesController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approve verification for ${request['caregiverName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes for approval',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adminService.approveVerification(
        requestId: request['id'],
        caregiverId: request['caregiverId'],
        notes: notesController.text.isEmpty ? null : notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Verification approved successfully' 
                : 'Failed to approve verification'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVerification(Map<String, dynamic> request) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject verification for ${request['caregiverName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Provide a reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      final success = await _adminService.rejectVerification(
        requestId: request['id'],
        caregiverId: request['caregiverId'],
        reason: reasonController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Verification rejected' 
                : 'Failed to reject verification'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }
}
