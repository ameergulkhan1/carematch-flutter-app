import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';

class WhatWeOfferPage extends StatelessWidget {
  const WhatWeOfferPage({super.key});

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
                      Text('What We Offer', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 16),
                      Text(
                        'Comprehensive care solutions for every family need',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features Grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: [
                      _buildOfferCard(
                        icon: Icons.verified_user,
                        title: 'Verified Caregivers',
                        description: 'All caregivers undergo thorough background checks, identity verification, and skill assessments to ensure safety and quality.',
                        color: AppColors.primary,
                      ),
                      _buildOfferCard(
                        icon: Icons.schedule,
                        title: 'Flexible Scheduling',
                        description: 'Book care services on-demand or schedule recurring appointments that fit your family\'s unique needs and timeline.',
                        color: AppColors.secondary,
                      ),
                      _buildOfferCard(
                        icon: Icons.medical_services,
                        title: 'Specialized Care',
                        description: 'Access caregivers trained in elderly care, child care, special needs support, and medical assistance.',
                        color: AppColors.accent,
                      ),
                      _buildOfferCard(
                        icon: Icons.security,
                        title: 'Secure Platform',
                        description: 'Your data is protected with enterprise-grade security. All transactions are encrypted and monitored.',
                        color: AppColors.primary,
                      ),
                      _buildOfferCard(
                        icon: Icons.support_agent,
                        title: '24/7 Support',
                        description: 'Our dedicated support team is available round the clock to assist with any questions or concerns.',
                        color: AppColors.secondary,
                      ),
                      _buildOfferCard(
                        icon: Icons.trending_up,
                        title: 'Care Plans',
                        description: 'Customized care plans tailored to individual needs, with progress tracking and regular updates.',
                        color: AppColors.accent,
                      ),
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

  Widget _buildOfferCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
