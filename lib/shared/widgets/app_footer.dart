import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'CareMatch',
                              style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Trusted Care Partner',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.facebook, color: Colors.white70),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.link, color: Colors.white70),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Quick Links
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Links', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                        const SizedBox(height: 16),
                        _FooterLink(text: 'What We Offer', route: AppRoutes.whatWeOffer),
                        _FooterLink(text: 'How It Works', route: AppRoutes.howItWorks),
                        _FooterLink(text: 'Service Types', route: AppRoutes.serviceTypes),
                        _FooterLink(text: 'Pricing', route: AppRoutes.pricing),
                      ],
                    ),
                  ),
                  // Support
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Support', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                        const SizedBox(height: 16),
                        _FooterLink(text: 'FAQ', route: '/faq'),
                        _FooterLink(text: 'Contact Us', route: '/contact'),
                        _FooterLink(text: 'Help Center', route: '/help'),
                      ],
                    ),
                  ),
                  // Legal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Legal', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                        const SizedBox(height: 16),
                        _FooterLink(text: 'Terms of Service', route: '/terms'),
                        _FooterLink(text: 'Privacy Policy', route: '/privacy'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                '© 2025 CareMatch. All rights reserved.',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final String route;

  const _FooterLink({required this.text, required this.route});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        ),
      ),
    );
  }
}
