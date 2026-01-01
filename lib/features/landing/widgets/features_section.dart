import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text('Why Choose CareMatch?', style: AppTextStyles.displaySmall),
              const SizedBox(height: 16),
              Text(
                'Everything you need for peace of mind',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              const Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  _FeatureCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Verified Caregivers',
                    description: 'All caregivers undergo thorough background checks',
                  ),
                  _FeatureCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Flexible Scheduling',
                    description: 'Book care on your terms - hourly, daily, or long-term',
                  ),
                  _FeatureCard(
                    icon: Icons.security_outlined,
                    title: 'Secure Payments',
                    description: 'Safe and secure payment processing',
                  ),
                  _FeatureCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Direct Communication',
                    description: 'Chat directly with caregivers before booking',
                  ),
                  _FeatureCard(
                    icon: Icons.star_border,
                    title: 'Quality Ratings',
                    description: 'Read reviews and ratings from other families',
                  ),
                  _FeatureCard(
                    icon: Icons.support_agent_outlined,
                    title: '24/7 Support',
                    description: 'Our support team is always here to help',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}