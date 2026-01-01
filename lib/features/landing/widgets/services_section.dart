import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

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
              Text('Care Services We Offer', style: AppTextStyles.displaySmall),
              const SizedBox(height: 48),
              const Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _ServiceCard(icon: Icons.child_care, title: 'Child Care'),
                  _ServiceCard(icon: Icons.elderly, title: 'Elderly Care'),
                  _ServiceCard(icon: Icons.accessible, title: 'Special Needs'),
                  _ServiceCard(icon: Icons.people, title: 'Companionship'),
                  _ServiceCard(icon: Icons.medical_services, title: 'Medical Assistance'),
                  _ServiceCard(icon: Icons.cleaning_services, title: 'Housekeeping'),
                  _ServiceCard(icon: Icons.restaurant, title: 'Meal Prep'),
                  _ServiceCard(icon: Icons.nightlight, title: 'Live-in Care'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ServiceCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
