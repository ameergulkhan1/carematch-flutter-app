import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../providers/caregiver_provider.dart';

class CaregiverSignupStep3 extends StatefulWidget {
  final String email;
  final String fullName;

  const CaregiverSignupStep3({
    super.key,
    required this.email,
    required this.fullName,
  });

  @override
  State<CaregiverSignupStep3> createState() => _CaregiverSignupStep3State();
}

class _CaregiverSignupStep3State extends State<CaregiverSignupStep3> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    print('🟡 CaregiverSignupStep3._sendOTP called for email: ${widget.email}, name: ${widget.fullName}');
    
    final caregiverProvider = Provider.of<CaregiverProvider>(context, listen: false);
    
    setState(() {
      _isResending = true;
    });

    final success = await caregiverProvider.sendOTP(widget.email, widget.fullName);

    setState(() {
      _isResending = false;
    });

    if (success) {
      print('✅ CaregiverSignupStep3: OTP sent successfully');
      _startCountdown();
      if (mounted) {
        // Show different message based on EmailJS configuration
        final message = AppConfig.emailJsPublicKey.isEmpty
            ? 'Verification code generated! Check the console/terminal for the code.'
            : 'Verification code sent to your email';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      print('❌ CaregiverSignupStep3: OTP sending failed');
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

  Future<void> _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final caregiverProvider = Provider.of<CaregiverProvider>(context, listen: false);
    final success = await caregiverProvider.verifyOTP(widget.email, otp);

    setState(() {
      _isVerifying = false;
    });

    if (success) {
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to step 4 (professional information)
      Navigator.pushReplacementNamed(context, '/caregiver-signup-step4');
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or expired code'),
          backgroundColor: AppColors.error,
        ),
      );
      
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator (3/5)
            Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index < 3 ? (index < 2 ? AppColors.success : AppColors.primary) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Step 3 of 5',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            const Icon(Icons.email_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 32),

            Text(
              'Verify Your Email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Text(
              'We\'ve sent a 6-digit code to',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              widget.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // OTP Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                        if (index == 5) _verifyOTP();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Verify Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),

            if (_resendCountdown > 0)
              Text(
                'Resend code in $_resendCountdown seconds',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              )
            else
              TextButton(
                onPressed: _isResending ? null : _sendOTP,
                child: _isResending
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Resend Code', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
