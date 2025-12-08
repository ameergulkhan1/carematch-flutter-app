import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

/// Client Signup Step 4 - Final Profile Setup
/// Location, Care Needs, Preferred Timings
class ClientSignupStep4 extends StatefulWidget {
  const ClientSignupStep4({super.key});

  @override
  State<ClientSignupStep4> createState() => _ClientSignupStep4State();
}

class _ClientSignupStep4State extends State<ClientSignupStep4> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  final Set<String> _selectedCareNeeds = {};
  final Set<String> _preferredTimings = {};
  String? _preferredGender;
  bool _isLoading = false;

  final List<String> _careNeedOptions = [
    'Childcare',
    'Elderly Care',
    'Special Needs Care',
    'Companionship',
    'Medical Care',
    'Dementia Care',
    'Post-Surgery Care',
    'Respite Care',
  ];

  final List<String> _timingOptions = [
    'Morning (6AM - 12PM)',
    'Afternoon (12PM - 6PM)',
    'Evening (6PM - 12AM)',
    'Night (12AM - 6AM)',
    'Weekdays',
    'Weekends',
    'Full-time',
    'Part-time',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCareNeeds.isEmpty) {
      _showError('Please select at least one care need');
      return;
    }
    if (_preferredTimings.isEmpty) {
      _showError('Please select at least one preferred timing');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final profileData = {
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _zipController.text.trim(),
        'careNeeds': _selectedCareNeeds.toList(),
        'preferredTimings': _preferredTimings.toList(),
        'preferredGender': _preferredGender,
        'emergencyContact': {
          'name': _emergencyContactNameController.text.trim(),
          'phone': _emergencyContactPhoneController.text.trim(),
        },
        'profileCompleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final success = await authProvider.updateProfile(profileData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.clientDashboard);
      } else {
        _showError('Failed to complete profile. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              _buildSectionTitle('Location Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Street Address',
                icon: Icons.home,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'City is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'State is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _zipController,
                label: 'ZIP Code',
                icon: Icons.pin_drop,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'ZIP code is required' : null,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Care Needs'),
              const SizedBox(height: 16),
              _buildCareNeedsSelection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Preferred Timings'),
              const SizedBox(height: 16),
              _buildTimingsSelection(),
              const SizedBox(height: 32),
              _buildSectionTitle('Preferences'),
              const SizedBox(height: 16),
              _buildGenderPreference(),
              const SizedBox(height: 32),
              _buildSectionTitle('Emergency Contact'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emergencyContactNameController,
                label: 'Contact Name',
                icon: Icons.person,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Emergency contact name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emergencyContactPhoneController,
                label: 'Contact Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Emergency contact phone is required';
                  }
                  if (value!.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepIndicator(1, true),
            _buildStepLine(true),
            _buildStepIndicator(2, true),
            _buildStepLine(true),
            _buildStepIndicator(3, true),
            _buildStepLine(true),
            _buildStepIndicator(4, false),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step 4 of 4',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, bool completed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: completed ? AppColors.primary : AppColors.primary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '$step',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool completed) {
    return Expanded(
      child: Container(
        height: 2,
        color: completed ? AppColors.primary : AppColors.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildCareNeedsSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _careNeedOptions.map((need) {
        final isSelected = _selectedCareNeeds.contains(need);
        return FilterChip(
          label: Text(need),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCareNeeds.add(need);
              } else {
                _selectedCareNeeds.remove(need);
              }
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimingsSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timingOptions.map((timing) {
        final isSelected = _preferredTimings.contains(timing);
        return FilterChip(
          label: Text(timing),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _preferredTimings.add(timing);
              } else {
                _preferredTimings.remove(timing);
              }
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenderPreference() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Caregiver Gender (Optional)',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('No Preference'),
                value: 'any',
                groupValue: _preferredGender,
                onChanged: (value) => setState(() => _preferredGender = value),
                activeColor: AppColors.primary,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Male'),
                value: 'male',
                groupValue: _preferredGender,
                onChanged: (value) => setState(() => _preferredGender = value),
                activeColor: AppColors.primary,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Female'),
                value: 'female',
                groupValue: _preferredGender,
                onChanged: (value) => setState(() => _preferredGender = value),
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
