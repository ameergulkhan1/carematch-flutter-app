import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/buttons.dart';

class CTASection extends StatelessWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'Ready to Get Started?',
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Join thousands of families who trust CareMatch for their care needs',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  PrimaryButton(
                    text: 'Find a Caregiver',
                    onPressed: () {
                      Navigator.pushNamed(context, '/search-caregivers');
                    },
                    icon: Icons.search,
                  ),
                  SecondaryButton(
                    text: 'Become a Caregiver',
                    onPressed: () {
                      Navigator.pushNamed(context, '/caregiver-signup-step1');
                    },
                    icon: Icons.work_outline,
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
