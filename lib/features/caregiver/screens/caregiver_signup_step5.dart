import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/caregiver_provider.dart';

class CaregiverSignupStep5 extends StatefulWidget {
  const CaregiverSignupStep5({super.key});

  @override
  State<CaregiverSignupStep5> createState() => _CaregiverSignupStep5State();
}

class _CaregiverSignupStep5State extends State<CaregiverSignupStep5> {
  final Map<String, PlatformFile?> _selectedFiles = {
    'id_proof': null,
    'address_proof': null,
    'certifications': null,
    'background_check': null,
  };

  final Map<String, String> _documentTitles = {
    'id_proof': 'Government ID',
    'address_proof': 'Proof of Address',
    'certifications': 'Certifications',
    'background_check': 'Background Check',
  };

  final Map<String, String> _documentDescriptions = {
    'id_proof': 'Driver\'s license, passport, or state ID',
    'address_proof': 'Utility bill, lease agreement, or bank statement',
    'certifications': 'CPR, First Aid, CNA, or other certifications',
    'background_check': 'Recent background check or criminal record clearance',
  };

  bool _isSubmitting = false;

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 5MB'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        setState(() {
          _selectedFiles[documentType] = file;
        });

        // Upload immediately
        _uploadDocument(documentType, file);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _uploadDocument(String documentType, PlatformFile file) async {
    final caregiverProvider = Provider.of<CaregiverProvider>(context, listen: false);
    
    final success = await caregiverProvider.uploadDocument(
      documentType: documentType,
      file: file,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_documentTitles[documentType]} uploaded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _selectedFiles[documentType] = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(caregiverProvider.errorMessage ?? 'Upload failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeDocument(String documentType) {
    setState(() {
      _selectedFiles[documentType] = null;
    });
    // Note: In a real app, you'd also delete from Firebase Storage here
  }

  Future<void> _submitDocuments() async {
    // Check if all required documents are uploaded
    final uploadedDocs = _selectedFiles.values.where((file) => file != null).length;
    
    if (uploadedDocs < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least ID proof and one other document'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final caregiverProvider = Provider.of<CaregiverProvider>(context, listen: false);
    final success = await caregiverProvider.submitDocumentsForVerification();

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      // Navigate to pending dashboard
      Navigator.pushReplacementNamed(context, '/caregiver-pending-dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(caregiverProvider.errorMessage ?? 'Submission failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<CaregiverProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Indicator (5/5)
                Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index < 5
                              ? (index < 4 ? AppColors.success : AppColors.primary)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step 5 of 5',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Text(
                  'Upload Required Documents',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All documents are securely stored and reviewed by our team',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),

                // Document Upload Cards
                ..._selectedFiles.keys.map((documentType) {
                  final file = _selectedFiles[documentType];
                  final isUploading = provider.uploadProgress[documentType] != null &&
                      provider.uploadProgress[documentType]! < 1.0;
                  final uploadProgress = provider.uploadProgress[documentType] ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: file != null
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    file != null ? Icons.check_circle : Icons.upload_file,
                                    color: file != null ? AppColors.success : AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _documentTitles[documentType]!,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _documentDescriptions[documentType]!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (file != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      file.extension == 'pdf'
                                          ? Icons.picture_as_pdf
                                          : Icons.image,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        file.name,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () => _removeDocument(documentType),
                                      color: AppColors.error,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (isUploading) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: uploadProgress,
                                backgroundColor: Colors.grey[300],
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Uploading... ${(uploadProgress * 100).toInt()}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                            if (file == null && !isUploading) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _pickFile(documentType),
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload Document'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // File requirements info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Document Requirements',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Accepted formats: PDF, JPG, PNG\n'
                        '• Maximum file size: 5MB\n'
                        '• Documents must be clear and readable\n'
                        '• At least ID proof and one other document required',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit for Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
