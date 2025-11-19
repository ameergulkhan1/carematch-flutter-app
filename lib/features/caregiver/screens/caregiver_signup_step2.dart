import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/caregiver_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';

class CaregiverSignupStep2 extends StatefulWidget {
  final String email;
  final String password;

  const CaregiverSignupStep2({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<CaregiverSignupStep2> createState() => _CaregiverSignupStep2State();
}

class _CaregiverSignupStep2State extends State<CaregiverSignupStep2> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.replaceAll(RegExp(r'[^\d]'), '').length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'ZIP code is required';
    }
    if (value.length != 5) {
      return 'ZIP code must be 5 digits';
    }
    return null;
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Calculate age
    final age = DateTime.now().difference(_selectedDate!).inDays ~/ 365;
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be at least 18 years old to register as a caregiver'),
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

    final success = await caregiverProvider.registerCaregiver(
      email: widget.email,
      password: widget.password,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
      dateOfBirth: _selectedDate!,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
    );

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    if (success) {
      // Navigate to step 3 (OTP verification)
      Navigator.pushReplacementNamed(
        context,
        '/caregiver-signup-step3',
        arguments: {
          'email': widget.email,
          'fullName': _fullNameController.text.trim(),
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(caregiverProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Sign Up'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Step 2 of 5',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) => _validateRequired(value, 'Full name'),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '(555) 123-4567',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: _dobController,
                    label: 'Date of Birth',
                    hint: 'MM/DD/YYYY',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    validator: (value) => _validateRequired(value, 'Date of birth'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Address',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _addressController,
                label: 'Street Address',
                hint: '123 Main St',
                prefixIcon: const Icon(Icons.home_outlined),
                validator: (value) => _validateRequired(value, 'Address'),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
                      validator: (value) => _validateRequired(value, 'City'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      label: 'State',
                      hint: 'NY',
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(2),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                      validator: (value) => _validateRequired(value, 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _zipCodeController,
                label: 'ZIP Code',
                hint: '12345',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                validator: _validateZipCode,
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
                  'Continue',
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
