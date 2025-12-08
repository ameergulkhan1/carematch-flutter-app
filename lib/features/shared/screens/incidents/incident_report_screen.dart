import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/incident_report_model.dart';
import '../../../../models/booking_model.dart';
import '../../../../services/incident_service.dart';

class IncidentReportScreen extends StatefulWidget {
  final BookingModel? booking;
  final String? caregiverId;
  final String? caregiverName;
  final String? clientId;
  final String? clientName;

  const IncidentReportScreen({
    super.key,
    this.booking,
    this.caregiverId,
    this.caregiverName,
    this.clientId,
    this.clientName,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final IncidentService _incidentService = IncidentService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  IncidentType _selectedType = IncidentType.serviceQualityIssue;
  IncidentSeverity _selectedSeverity = IncidentSeverity.medium;
  List<File> _evidenceFiles = [];
  bool _isSubmitting = false;
  DateTime _incidentDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage();
      if (files.isNotEmpty && _evidenceFiles.length + files.length <= 10) {
        setState(() {
          _evidenceFiles.addAll(files.map((xfile) => File(xfile.path)));
        });
      } else if (_evidenceFiles.length + files.length > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 evidence files allowed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  void _removeEvidence(int index) {
    setState(() {
      _evidenceFiles.removeAt(index);
    });
  }

  Future<void> _selectIncidentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Determine reporter role
      String reporterRole = 'client'; // Default
      // You would get this from user profile in real implementation

      // Create incident report
      final incidentId = await _incidentService.createIncidentReport(
        type: _selectedType,
        severity: _selectedSeverity,
        reporterId: currentUser.uid,
        reporterName: currentUser.displayName ?? currentUser.email ?? 'User',
        reporterRole: reporterRole,
        bookingId: widget.booking?.id,
        caregiverId: widget.caregiverId ?? widget.booking?.caregiverId,
        caregiverName: widget.caregiverName ?? widget.booking?.caregiverName,
        clientId: widget.clientId ?? widget.booking?.clientId,
        clientName: widget.clientName ?? widget.booking?.clientName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        incidentDate: _incidentDate,
        tags: [_selectedType.name, _selectedSeverity.name],
      );

      if (incidentId == null) {
        throw Exception('Failed to create incident report');
      }

      // Upload evidence
      for (var file in _evidenceFiles) {
        await _incidentService.uploadEvidence(
          file: file,
          incidentId: incidentId,
          uploadedBy: currentUser.uid,
          fileType: 'photo',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Incident reported successfully. ID: ${incidentId.substring(0, 8)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWarningBanner(),
            const SizedBox(height: 24),
            _buildIncidentTypeSelector(),
            const SizedBox(height: 16),
            _buildSeveritySelector(),
            const SizedBox(height: 16),
            _buildIncidentDatePicker(),
            const SizedBox(height: 16),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildEvidenceSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'For emergencies, please call emergency services immediately. This form is for non-emergency incident reporting.',
              style: TextStyle(color: Colors.red[900], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<IncidentType>(
          value: _selectedType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: IncidentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getIncidentTypeLabel(type)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSeveritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Severity Level',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: IncidentSeverity.values.map((severity) {
            final isSelected = _selectedSeverity == severity;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSeverity = severity),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getSeverityColor(severity)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _getSeverityColor(severity)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    severity.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIncidentDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When did this occur?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectIncidentDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident Title',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Brief description of the incident',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Description',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Provide detailed information about what happened...',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Evidence (Photos/Documents)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _evidenceFiles.length < 10 ? _pickEvidence : null,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add Files'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_evidenceFiles.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_evidenceFiles.length, (index) {
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_evidenceFiles[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeEvidence(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitReport,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
              'Submit Incident Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  String _getIncidentTypeLabel(IncidentType type) {
    switch (type) {
      case IncidentType.safetyViolation:
        return 'Safety Violation';
      case IncidentType.professionalMisconduct:
        return 'Professional Misconduct';
      case IncidentType.serviceQualityIssue:
        return 'Service Quality Issue';
      case IncidentType.clientComplaint:
        return 'Client Complaint';
      case IncidentType.caregiverComplaint:
        return 'Caregiver Complaint';
      case IncidentType.paymentDispute:
        return 'Payment Dispute';
      case IncidentType.noShow:
        return 'No Show';
      case IncidentType.inappropriateBehavior:
        return 'Inappropriate Behavior';
      case IncidentType.damageToProperty:
        return 'Damage to Property';
      case IncidentType.medicalIncident:
        return 'Medical Incident';
      case IncidentType.other:
        return 'Other';
    }
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.blue;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.deepOrange;
      case IncidentSeverity.critical:
        return Colors.red;
    }
  }
}
