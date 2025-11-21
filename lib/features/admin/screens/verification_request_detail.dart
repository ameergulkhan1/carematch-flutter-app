import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/admin_verification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/info_section.dart';
import '../widgets/info_row.dart';
import '../widgets/document_tile.dart';
import '../widgets/status_badge.dart';

class VerificationRequestDetail extends StatefulWidget {
  const VerificationRequestDetail({super.key});

  @override
  State<VerificationRequestDetail> createState() => _VerificationRequestDetailState();
}

class _VerificationRequestDetailState extends State<VerificationRequestDetail> {
  final AdminVerificationService _verificationService = AdminVerificationService();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rejectionReasonController = TextEditingController();
  
  Map<String, dynamic>? _caregiverData;
  List<Map<String, dynamic>> _documentHistory = [];
  bool _isLoading = true;
  String? _requestId;
  String? _caregiverId;
  
  final List<String> _selectedDocumentsForRevision = [];
  final List<String> _selectedRejectedDocuments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _requestId = args['requestId'] as String;
    _caregiverId = args['caregiverId'] as String;

    if (_caregiverId == null) return;

    setState(() => _isLoading = true);

    final caregiverData = await _verificationService.getCaregiverDetails(_caregiverId!);
    final documentHistory = await _verificationService.getDocumentHistory(_caregiverId!);

    setState(() {
      _caregiverData = caregiverData;
      _documentHistory = documentHistory;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verification Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_caregiverData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verification Details'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Caregiver not found')),
      );
    }

    final documents = Map<String, String>.from(_caregiverData!['documents'] ?? {});
    final verificationStatus = _caregiverData!['verificationStatus'] ?? 'pending';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Verification Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: StatusBadge(status: verificationStatus),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Caregiver Info
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_caregiverData!['firstName'] ?? ''} ${_caregiverData!['lastName'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _caregiverData!['email'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _caregiverData!['phone'] ?? 'No phone',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Professional Information
            InfoSection(
              title: 'Professional Information',
              icon: Icons.work_outline,
              content: Column(
                children: [
                  InfoRow(
                    label: 'Experience',
                    value: '${_caregiverData!['yearsOfExperience'] ?? 'N/A'} years',
                  ),
                  const Divider(height: 24),
                  InfoRow(
                    label: 'Specializations',
                    value: ((_caregiverData!['specializations'] as List?) ?? []).join(', '),
                  ),
                  const Divider(height: 24),
                  InfoRow(
                    label: 'Certifications',
                    value: ((_caregiverData!['certifications'] as List?) ?? []).join(', '),
                  ),
                  const Divider(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bio',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _caregiverData!['bio'] ?? 'No bio provided',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Documents Section
            InfoSection(
              title: 'Uploaded Documents',
              icon: Icons.folder_outlined,
              content: Column(
                children: [
                  if (documents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No documents uploaded'),
                    )
                  else
                    ...documents.entries.map((entry) {
                      final docType = entry.key;
                      final docIdOrPath = entry.value;
                      
                      return DocumentTile(
                        docName: docType,
                        docUrl: docIdOrPath,
                        isSelected: _selectedDocumentsForRevision.contains(docType),
                        showCheckbox: verificationStatus == 'pending',
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDocumentsForRevision.add(docType);
                            } else {
                              _selectedDocumentsForRevision.remove(docType);
                            }
                          });
                        },
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Document History Timeline
            if (_documentHistory.isNotEmpty)
              InfoSection(
                title: 'Document History',
                icon: Icons.history,
                content: Column(
                  children: _documentHistory.map((doc) {
                    final uploadedAt = (doc['uploadedAt'] as Timestamp?)?.toDate();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.upload_file, color: AppColors.primary, size: 20),
                      ),
                      title: Text(_formatDocumentType(doc['documentType'] ?? '')),
                      subtitle: Text(
                        uploadedAt != null
                            ? DateFormat('MMM dd, yyyy - hh:mm a').format(uploadedAt)
                            : 'Date unknown',
                      ),
                      trailing: Text(
                        _formatFileSize(doc['fileSize'] ?? 0),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons (only if status is pending or revision_requested)
            if (verificationStatus == 'pending' || verificationStatus == 'revision_requested')
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Approve Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showApproveDialog(),
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Approve Application',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Request Revision Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRequestRevisionDialog(),
                        icon: const Icon(Icons.edit_note),
                        label: const Text(
                          'Request Document Revision',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.blue, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reject Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(),
                        icon: const Icon(Icons.cancel),
                        label: const Text(
                          'Reject Application',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.error, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDocumentType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Text('Approve Application'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a welcome message or approval notes for the caregiver:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., Congratulations! Your application has been approved. You can now start receiving bookings...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _approveVerification(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRequestRevisionDialog() {
    final documents = Map<String, String>.from(_caregiverData!['documents'] ?? {});
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blue, size: 28),
              SizedBox(width: 12),
              Text('Request Revision'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select documents that need revision:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...documents.keys.map((docType) {
                  return CheckboxListTile(
                    title: Text(_formatDocumentType(docType)),
                    value: _selectedDocumentsForRevision.contains(docType),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          _selectedDocumentsForRevision.add(docType);
                        } else {
                          _selectedDocumentsForRevision.remove(docType);
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Explain what needs to be corrected:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g., ID document image is unclear. Please upload a clearer photo...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _selectedDocumentsForRevision.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _selectedDocumentsForRevision.isEmpty
                  ? null
                  : () => _requestRevision(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Request Revision'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    final documents = Map<String, String>.from(_caregiverData!['documents'] ?? {});
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel, color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Text('Reject Application'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action will reject the application permanently.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select problematic documents (optional):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...documents.keys.map((docType) {
                  return CheckboxListTile(
                    title: Text(_formatDocumentType(docType)),
                    value: _selectedRejectedDocuments.contains(docType),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          _selectedRejectedDocuments.add(docType);
                        } else {
                          _selectedRejectedDocuments.remove(docType);
                        }
                      });
                    },
                    activeColor: AppColors.error,
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Reason for rejection:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rejectionReasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g., Invalid credentials, fake documents, does not meet minimum requirements...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _selectedRejectedDocuments.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _rejectVerification(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveVerification() async {
    Navigator.pop(context); // Close dialog
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final success = await _verificationService.approveVerification(
      requestId: _requestId!,
      caregiverId: _caregiverId!,
      adminId: adminId,
      adminNotes: _notesController.text.trim().isEmpty
          ? 'Your application has been approved. Welcome to CareMatch!'
          : _notesController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Application approved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // Return to dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve application'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    _notesController.clear();
  }

  Future<void> _requestRevision() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide revision notes'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pop(context); // Close dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final success = await _verificationService.requestRevision(
      requestId: _requestId!,
      caregiverId: _caregiverId!,
      adminId: adminId,
      revisionNotes: _notesController.text.trim(),
      documentsToRevise: _selectedDocumentsForRevision,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📝 Revision request sent successfully'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.pop(context); // Return to dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send revision request'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    _notesController.clear();
    _selectedDocumentsForRevision.clear();
  }

  Future<void> _rejectVerification() async {
    if (_rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pop(context); // Close dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final success = await _verificationService.rejectVerification(
      requestId: _requestId!,
      caregiverId: _caregiverId!,
      adminId: adminId,
      rejectionReason: _rejectionReasonController.text.trim(),
      rejectedDocuments: _selectedRejectedDocuments,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Application rejected'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context); // Return to dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject application'),
          backgroundColor: AppColors.error,
        ),
      );
    }

    _rejectionReasonController.clear();
    _selectedRejectedDocuments.clear();
  }
}
