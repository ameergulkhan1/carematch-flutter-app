import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text('How It Works', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 16),
                      Text(
                        'Simple steps to connect with trusted caregivers',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // For Families
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text('For Families', style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 48),
                      _buildStepCard(1, 'Create Your Account', 'Sign up and complete your profile with care requirements and preferences.', Icons.person_add),
                      const SizedBox(height: 32),
                      _buildStepCard(2, 'Browse Caregivers', 'Search and filter verified caregivers based on location, skills, and availability.', Icons.search),
                      const SizedBox(height: 32),
                      _buildStepCard(3, 'Review & Select', 'View detailed profiles, ratings, and reviews to choose the perfect caregiver.', Icons.rate_review),
                      const SizedBox(height: 32),
                      _buildStepCard(4, 'Book & Connect', 'Schedule services, communicate securely, and manage care through our platform.', Icons.calendar_month),
                    ],
                  ),
                ),
              ),
            ),

            // Divider
            const Divider(height: 1),

            // For Caregivers
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              color: AppColors.backgroundLight,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text('For Caregivers', style: AppTextStyles.displayMedium.copyWith(color: AppColors.secondary)),
                      const SizedBox(height: 48),
                      _buildStepCard(1, 'Register & Verify', 'Complete registration and submit required documents for verification.', Icons.verified_user),
                      const SizedBox(height: 32),
                      _buildStepCard(2, 'Build Your Profile', 'Showcase your skills, experience, certifications, and availability.', Icons.work),
                      const SizedBox(height: 32),
                      _buildStepCard(3, 'Get Approved', 'Our admin team reviews and approves your profile after verification.', Icons.check_circle),
                      const SizedBox(height: 32),
                      _buildStepCard(4, 'Start Earning', 'Receive booking requests, accept jobs, and build your reputation.', Icons.attach_money),
                    ],
                  ),
                ),
              ),
            ),

            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$step',
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: AppTextStyles.titleLarge)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
