import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

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
                      Text('Transparent Pricing', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 16),
                      Text(
                        'Simple, fair pricing with no hidden fees',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pricing Cards
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPricingCard(
                        title: 'For Families',
                        price: 'Free',
                        period: 'Forever',
                        description: 'No subscription fees for families seeking care',
                        features: [
                          'Unlimited caregiver search',
                          'Direct messaging',
                          'Booking management',
                          'Review & ratings',
                          'Secure payments',
                          '24/7 customer support',
                        ],
                        isPopular: false,
                      ),
                      _buildPricingCard(
                        title: 'Platform Fee',
                        price: '15%',
                        period: 'Per Booking',
                        description: 'Service fee on each completed booking',
                        features: [
                          'Secure payment processing',
                          'Background verification',
                          'Insurance coverage',
                          'Dispute resolution',
                          'Quality assurance',
                          'Platform maintenance',
                        ],
                        isPopular: true,
                      ),
                      _buildPricingCard(
                        title: 'For Caregivers',
                        price: 'Free',
                        period: 'Registration',
                        description: 'Join our platform at no upfront cost',
                        features: [
                          'Profile creation',
                          'Receive booking requests',
                          'Flexible scheduling',
                          'Earnings tracking',
                          'Professional development',
                          'Community support',
                        ],
                        isPopular: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Hourly Rates Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              color: AppColors.backgroundLight,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text('Average Hourly Rates', style: AppTextStyles.displayMedium),
                      const SizedBox(height: 16),
                      Text(
                        'Rates vary by location, experience, and service type',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 48),
                      Wrap(
                        spacing: 32,
                        runSpacing: 24,
                        children: [
                          _buildRateCard('Child Care', '\$15 - \$25/hr'),
                          _buildRateCard('Elderly Care', '\$18 - \$30/hr'),
                          _buildRateCard('Special Needs', '\$20 - \$35/hr'),
                          _buildRateCard('Medical Care', '\$25 - \$45/hr'),
                          _buildRateCard('Overnight Care', '\$100 - \$200/night'),
                          _buildRateCard('Respite Care', '\$18 - \$28/hr'),
                        ],
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

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required bool isPopular,
  }) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular ? Border.all(color: AppColors.primary, width: 2) : null,
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
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('RECOMMENDED', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
            ),
          if (isPopular) const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(price, style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(period, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(feature, style: AppTextStyles.bodyMedium)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRateCard(String service, String rate) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(service, style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(rate, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
