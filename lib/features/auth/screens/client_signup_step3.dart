import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/buttons.dart';

class ClientSignUpStep3 extends StatefulWidget {
  final String email;
  final String fullName;

  const ClientSignUpStep3({
    super.key,
    required this.email,
    required this.fullName,
  });

  @override
  State<ClientSignUpStep3> createState() => _ClientSignUpStep3State();
}

class _ClientSignUpStep3State extends State<ClientSignUpStep3> {
  final List<TextEditingController> _otpControllers = List.generate(
    AppConfig.otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    AppConfig.otpLength,
    (_) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    // Schedule OTP sending after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOTP();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOTP() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isResending = true;
    });

    final success = await authProvider.sendOTP(widget.email, widget.fullName);

    setState(() {
      _isResending = false;
      _otpSent = success;
    });

    if (success) {
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent to your email'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send verification code. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != AppConfig.otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete verification code'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isValid = await authProvider.verifyOTP(widget.email, otp);

    setState(() {
      _isVerifying = false;
    });

    if (isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to client dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.clientDashboard,
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired verification code'),
            backgroundColor: AppColors.error,
          ),
        );
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Verify Your Email',
                    style: AppTextStyles.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ve sent a ${AppConfig.otpLength}-digit verification code to',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step 3 of 3: Email Verification',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      AppConfig.otpLength,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: 50,
                          height: 60,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: AppTextStyles.headlineMedium,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              if (value.isNotEmpty && index < AppConfig.otpLength - 1) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }
                              
                              // Auto-verify when all digits entered
                              if (index == AppConfig.otpLength - 1 && value.isNotEmpty) {
                                final allFilled = _otpControllers.every((c) => c.text.isNotEmpty);
                                if (allFilled) {
                                  _verifyOTP();
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verify Button
                  PrimaryButton(
                    text: 'Verify Email',
                    onPressed: _verifyOTP,
                    isLoading: _isVerifying,
                    icon: Icons.verified_user,
                  ),
                  const SizedBox(height: 24),

                  // Resend Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_resendCountdown > 0)
                        Text(
                          'Resend in ${_resendCountdown}s',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textLight,
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _isResending ? null : _sendOTP,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  'Resend',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Skip for now (for testing)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.clientDashboard,
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Skip for now',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
