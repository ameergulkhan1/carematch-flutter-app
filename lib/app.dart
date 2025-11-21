import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/caregiver_provider.dart';
import 'features/landing/screens/landing_page.dart';
import 'features/landing/screens/what_we_offer_page.dart';
import 'features/landing/screens/how_it_works_page.dart';
import 'features/landing/screens/service_types_page.dart';
import 'features/landing/screens/pricing_page.dart';
import 'features/landing/screens/faq_page.dart';
import 'features/auth/screens/client_login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/email_verification_screen.dart';
import 'features/auth/screens/client_signup_step1.dart';
import 'features/auth/screens/client_signup_step2.dart';
import 'features/auth/screens/client_signup_step3.dart';
import 'features/client/screens/dashboard/client_dashboard_main.dart';
import 'features/client/screens/search_caregivers_screen.dart';
import 'features/caregiver/screens/caregiver_signup_step1.dart';
import 'features/caregiver/screens/caregiver_signup_step2.dart';
import 'features/caregiver/screens/caregiver_signup_step3.dart';
import 'features/caregiver/screens/caregiver_signup_step4.dart';
import 'features/caregiver/screens/caregiver_signup_step5.dart';
import 'features/caregiver/screens/caregiver_pending_dashboard.dart';
import 'features/caregiver/screens/approved_dashboard/caregiver_dashboard_main.dart';
import 'features/admin/admin_routes.dart';
import 'features/admin/screens/admin_login_screen.dart';
import 'features/admin/screens/dashboard/admin_dashboard_main.dart';
import 'features/admin/screens/admin_users_screen.dart';
import 'features/admin/screens/admin_caregivers_screen.dart';
import 'features/admin/screens/admin_verifications_screen.dart';
import 'features/admin/screens/admin_documents_screen.dart';

class CareMatchApp extends StatelessWidget {
  const CareMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CaregiverProvider()),
      ],
      child: MaterialApp(
        title: 'CareMatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.landing,
        routes: {
          // Landing & Public Pages
          AppRoutes.landing: (context) => const LandingPage(),
          AppRoutes.whatWeOffer: (context) => const WhatWeOfferPage(),
          AppRoutes.howItWorks: (context) => const HowItWorksPage(),
          AppRoutes.serviceTypes: (context) => const ServiceTypesPage(),
          AppRoutes.pricing: (context) => const PricingPage(),
          AppRoutes.faq: (context) => const FaqPage(),
          
          // Authentication
          AppRoutes.login: (context) => const ClientLoginScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/email-verification': (context) => const EmailVerificationScreen(),
          AppRoutes.signupClient: (context) => const ClientSignUpStep1(),
          '/client-signup-step2': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ClientSignUpStep2(
              email: args['email'],
              password: args['password'],
            );
          },
          '/client-signup-step3': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ClientSignUpStep3(
              email: args['email'],
              fullName: args['fullName'],
            );
          },
          
          // Caregiver Routes
          '/caregiver-signup-step1': (context) => const CaregiverSignupStep1(),
          '/caregiver-signup-step2': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return CaregiverSignupStep2(
              email: args['email'],
              password: args['password'],
            );
          },
          '/caregiver-signup-step3': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return CaregiverSignupStep3(
              email: args['email'],
              fullName: args['fullName'],
            );
          },
          '/caregiver-signup-step4': (context) => const CaregiverSignupStep4(),
          '/caregiver-signup-step5': (context) => const CaregiverSignupStep5(),
          AppRoutes.caregiverPendingDashboard: (context) => const CaregiverPendingDashboard(),
          AppRoutes.caregiverDashboard: (context) => const CaregiverDashboard(),
          
          // Client Routes
          AppRoutes.clientDashboard: (context) => const ClientDashboardMain(),
          '/search-caregivers': (context) => const SearchCaregiversScreen(),
          
          // Admin Routes
          AdminRoutes.adminLogin: (context) => const AdminLoginScreen(),
          AdminRoutes.adminDashboard: (context) => const AdminDashboardMain(),
          AdminRoutes.adminUsers: (context) => const AdminUsersScreen(),
          AdminRoutes.adminCaregivers: (context) => const AdminCaregiversScreen(),
          AdminRoutes.adminVerifications: (context) => const AdminVerificationsScreen(),
          AdminRoutes.adminDocuments: (context) => const AdminDocumentsScreen(),
          AdminRoutes.adminBookings: (context) => const Scaffold(
            body: Center(child: Text('Bookings - Coming Soon')),
          ),
          AdminRoutes.adminAnalytics: (context) => const Scaffold(
            body: Center(child: Text('Analytics - Coming Soon')),
          ),
          AdminRoutes.adminSettings: (context) => const Scaffold(
            body: Center(child: Text('Settings - Coming Soon')),
          ),
        },
      ),
    );
  }
}
