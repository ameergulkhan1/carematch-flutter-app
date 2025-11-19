import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_footer.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/services_section.dart';
import '../widgets/stats_section.dart';
import '../widgets/cta_section.dart';
import '../../admin/admin_routes.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(),
            FeaturesSection(),
            HowItWorksSection(),
            ServicesSection(),
            StatsSection(),
            CTASection(),
            AppFooter(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AdminRoutes.adminLogin);
        },
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Admin'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
