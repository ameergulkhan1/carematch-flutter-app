import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(value: '5,000+', label: 'Verified Caregivers'),
              _StatItem(value: '25,000+', label: 'Families Served'),
              _StatItem(value: '4.9/5', label: 'Average Rating'),
              _StatItem(value: '50+', label: 'Cities Covered'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.displayMedium.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFFE5E7EB))),
      ],
    );
  }
}
