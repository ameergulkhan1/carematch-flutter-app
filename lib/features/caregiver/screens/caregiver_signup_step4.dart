import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/caregiver_provider.dart';

class CaregiverSignupStep4 extends StatefulWidget {
  const CaregiverSignupStep4({super.key});

  @override
  State<CaregiverSignupStep4> createState() => _CaregiverSignupStep4State();
}

class _CaregiverSignupStep4State extends State<CaregiverSignupStep4> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  
  int _yearsOfExperience = 0;
  final List<String> _selectedSpecializations = [];
  final List<String> _selectedCertifications = [];

  final List<String> _availableSpecializations = [
    'Elderly Care',
    'Dementia Care',
    'Alzheimer\'s Care',
    'Post-Surgery Care',
    'Disability Care',
    'Palliative Care',
    'Respite Care',
    'Personal Care',
    'Companionship',
    'Medication Management',
    'Mobility Assistance',
    'Meal Preparation',
  ];

  final List<String> _availableCertifications = [
    'CPR Certified',
    'First Aid',
    'CNA (Certified Nursing Assistant)',
    'HHA (Home Health Aide)',
    'PCA (Personal Care Assistant)',
    'Dementia Care Specialist',
    'Alzheimer\'s Care Training',
    'Medication Administration',
    'Hospice Care Training',
    'Physical Therapy Aide',
    'Mental Health First Aid',
    'Infection Control',
  ];

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 50) {
      return 'Please provide at least 50 characters';
    }
    return null;
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialization'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCertifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one certification'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final caregiverProvider = Provider.of<CaregiverProvider>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await caregiverProvider.updateProfessionalInfo(
      yearsOfExperience: _yearsOfExperience.toString(),
      specializations: _selectedSpecializations,
      bio: _bioController.text.trim(),
      certifications: _selectedCertifications,
    );

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    if (success) {
      // Navigate to step 5 (document upload)
      Navigator.pushReplacementNamed(context, '/caregiver-signup-step5');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(caregiverProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Information'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator (4/5)
              Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index < 4
                            ? (index < 3 ? AppColors.success : AppColors.primary)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 4 of 5',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Text(
                'Tell us about your experience',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps families find the right caregiver',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Years of Experience
              Text(
                'Years of Experience',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _yearsOfExperience,
                    isExpanded: true,
                    items: List.generate(51, (index) => index).map((years) {
                      return DropdownMenuItem(
                        value: years,
                        child: Text(years == 0
                            ? 'Less than 1 year'
                            : years == 50
                                ? '50+ years'
                                : '$years ${years == 1 ? 'year' : 'years'}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _yearsOfExperience = value ?? 0;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Specializations
              Text(
                'Specializations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all that apply',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSpecializations.map((spec) {
                  final isSelected = _selectedSpecializations.contains(spec);
                  return FilterChip(
                    label: Text(spec),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSpecializations.add(spec);
                        } else {
                          _selectedSpecializations.remove(spec);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Bio
              Text(
                'About You',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your experience and what makes you a great caregiver (minimum 50 characters)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Tell families about your caregiving experience, approach, and what you enjoy most about helping others...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) => _validateRequired(value, 'Bio'),
              ),
              const SizedBox(height: 24),

              // Certifications
              Text(
                'Certifications & Training',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select all certifications you hold',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCertifications.map((cert) {
                  final isSelected = _selectedCertifications.contains(cert);
                  return FilterChip(
                    label: Text(cert),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCertifications.add(cert);
                        } else {
                          _selectedCertifications.remove(cert);
                        }
                      });
                    },
                    selectedColor: AppColors.success.withOpacity(0.2),
                    checkmarkColor: AppColors.success,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Continue Button
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Document Upload',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
