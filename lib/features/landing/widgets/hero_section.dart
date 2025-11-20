import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/buttons.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isSmallScreen
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Trusted Care',
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 56,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For Your Loved Ones',
                style: AppTextStyles.displayMedium.copyWith(
                  color: Colors.white70,
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Connect with verified, compassionate caregivers in your area. Professional care for children, elderly, and special needs.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFFE5E7EB),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  PrimaryButton(
                    text: 'Find a Caregiver',
                    onPressed: () {
                      Navigator.pushNamed(context, '/search-caregivers');
                    },
                    icon: Icons.search,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/caregiver-signup-step1');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.work_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Become a Caregiver',
                          style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Container(
            height: 500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=800'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Text(
          'Find Trusted Care',
          style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Connect with verified caregivers in your area',
          style: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFFE5E7EB)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Find a Caregiver',
          onPressed: () {
            Navigator.pushNamed(context, '/search-caregivers');
          },
          width: double.infinity,
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          text: 'Become a Caregiver',
          onPressed: () {
            Navigator.pushNamed(context, '/caregiver-signup-step1');
          },
          width: double.infinity,
        ),
      ],
    );
  }
}
