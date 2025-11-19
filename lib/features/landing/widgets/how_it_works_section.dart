import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text('How It Works', style: AppTextStyles.displaySmall),
              const SizedBox(height: 16),
              Text(
                'Getting started is easy',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              const Row(
                children: [
                  Expanded(child: _StepCard(step: '1', title: 'Create Profile', icon: Icons.person_add)),
                  SizedBox(width: 24),
                  Expanded(child: _StepCard(step: '2', title: 'Find Match', icon: Icons.search)),
                  SizedBox(width: 24),
                  Expanded(child: _StepCard(step: '3', title: 'Book Care', icon: Icons.calendar_today)),
                  SizedBox(width: 24),
                  Expanded(child: _StepCard(step: '4', title: 'Get Care', icon: Icons.favorite)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final IconData icon;

  const _StepCard({required this.step, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
      ],
    );
  }
}
