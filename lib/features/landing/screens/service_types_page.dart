import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';

class ServiceTypesPage extends StatelessWidget {
  const ServiceTypesPage({super.key});

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
                      Text('Our Services', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 16),
                      Text(
                        'Professional care services tailored to your needs',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Services Grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: [
                      _buildServiceCard(
                        icon: Icons.child_care,
                        title: 'Child Care',
                        description: 'Professional nannies and babysitters for infants, toddlers, and children of all ages.',
                        features: ['Age-appropriate activities', 'Meal preparation', 'Homework help', 'Safe supervision'],
                      ),
                      _buildServiceCard(
                        icon: Icons.elderly,
                        title: 'Elderly Care',
                        description: 'Compassionate caregivers for seniors needing assistance with daily activities.',
                        features: ['Companionship', 'Medication reminders', 'Mobility assistance', 'Personal care'],
                      ),
                      _buildServiceCard(
                        icon: Icons.accessible,
                        title: 'Special Needs Care',
                        description: 'Trained specialists for individuals with physical or developmental disabilities.',
                        features: ['Therapeutic support', 'Specialized training', 'Adaptive care', 'Family support'],
                      ),
                      _buildServiceCard(
                        icon: Icons.medical_services,
                        title: 'Medical Care',
                        description: 'Licensed nurses and medical professionals for health-related assistance.',
                        features: ['Medication management', 'Vital monitoring', 'Wound care', 'Post-surgery support'],
                      ),
                      _buildServiceCard(
                        icon: Icons.nights_stay,
                        title: 'Overnight Care',
                        description: 'Round-the-clock care for those requiring nighttime supervision and assistance.',
                        features: ['Sleep monitoring', 'Emergency response', 'Comfort care', 'Peace of mind'],
                      ),
                      _buildServiceCard(
                        icon: Icons.home,
                        title: 'Respite Care',
                        description: 'Temporary relief for primary caregivers to rest and recharge.',
                        features: ['Flexible scheduling', 'Trained replacements', 'Seamless transition', 'Short or long-term'],
                      ),
                      _buildServiceCard(
                        icon: Icons.healing,
                        title: 'Dementia Care',
                        description: 'Specialized care for individuals with Alzheimer\'s and other forms of dementia.',
                        features: ['Memory care', 'Safety protocols', 'Behavioral management', 'Family education'],
                      ),
                      _buildServiceCard(
                        icon: Icons.favorite,
                        title: 'Palliative Care',
                        description: 'Compassionate end-of-life care focused on comfort and quality of life.',
                        features: ['Pain management', 'Emotional support', 'Dignity care', 'Family counseling'],
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

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
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
          Icon(icon, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
