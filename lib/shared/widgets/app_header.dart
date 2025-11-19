import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showActions;

  const AppHeader({super.key, this.showActions = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'CareMatch',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: showActions
          ? [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.whatWeOffer),
                child: Text('What We Offer', style: AppTextStyles.labelLarge),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.howItWorks),
                child: Text('How It Works', style: AppTextStyles.labelLarge),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.serviceTypes),
                child: Text('Services', style: AppTextStyles.labelLarge),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.pricing),
                child: Text('Pricing', style: AppTextStyles.labelLarge),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.faq),
                child: Text('FAQ', style: AppTextStyles.labelLarge),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text('Sign In', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
