import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/buttons.dart';
import 'client_signup_step3.dart';

class ClientSignUpStep2 extends StatefulWidget {
  final String email;
  final String password;

  const ClientSignUpStep2({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<ClientSignUpStep2> createState() => _ClientSignUpStep2State();
}

class _ClientSignUpStep2State extends State<ClientSignUpStep2> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''))) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateZipCode(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length != 5 && value.length != 6) {
        return 'Enter a valid zip code';
      }
    }
    return null;
  }

  void _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Register user
    final success = await authProvider.registerClient(
      email: widget.email,
      password: widget.password,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      zipCode: _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
    );

    // Hide loading
    if (mounted) Navigator.pop(context);

    if (success) {
      // Navigate to email verification
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientSignUpStep3(
              email: widget.email,
              fullName: _fullNameController.text.trim(),
            ),
          ),
        );
      }
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text('Personal Information', style: AppTextStyles.displaySmall),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about yourself',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),

                    // Progress Indicator
                    Row(
                      children: [
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
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step 2 of 3: Personal Details',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Full Name
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      prefixIcon: const Icon(Icons.person_outlined),
                      validator: _validateFullName,
                    ),
                    const SizedBox(height: 24),

                    // Phone Number
                    CustomTextField(
                      label: 'Phone Number',
                      hint: '(123) 456-7890',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: _validatePhone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Address (Optional)
                    CustomTextField(
                      label: 'Address (Optional)',
                      hint: 'Street address',
                      controller: _addressController,
                      keyboardType: TextInputType.streetAddress,
                      prefixIcon: const Icon(Icons.home_outlined),
                    ),
                    const SizedBox(height: 24),

                    // City and State
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: 'City (Optional)',
                            hint: 'City',
                            controller: _cityController,
                            keyboardType: TextInputType.text,
                            prefixIcon: const Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: 'State (Optional)',
                            hint: 'CA',
                            controller: _stateController,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) => TextEditingValue(
                                  text: newValue.text.toUpperCase(),
                                  selection: newValue.selection,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Zip Code
                    CustomTextField(
                      label: 'Zip Code (Optional)',
                      hint: '12345',
                      controller: _zipCodeController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.pin_drop_outlined),
                      validator: _validateZipCode,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Continue Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return PrimaryButton(
                          text: 'Create Account',
                          onPressed: _handleNext,
                          isLoading: authProvider.isLoading,
                          icon: Icons.check_circle_outline,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
