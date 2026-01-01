/// CareMatch App Constants
/// All static configuration values
class AppConstants {
  // App Info
  static const String appName = 'CareMatch';
  static const String appTagline = 'Your Trusted Care Partner';
  static const String appVersion = '1.0.0';
  
  // Contact Info
  static const String supportEmail = 'support@carematch.com';
  static const String supportPhone = '+1 (555) 123-4567';
  static const String websiteUrl = 'https://carematch.com';
  
  // Social Media
  static const String facebookUrl = 'https://facebook.com/carematch';
  static const String twitterUrl = 'https://twitter.com/carematch';
  static const String instagramUrl = 'https://instagram.com/carematch';
  static const String linkedinUrl = 'https://linkedin.com/company/carematch';
  
  // Service Types
  static const List<String> serviceTypes = [
    'Child Care',
    'Elderly Care',
    'Special Needs Care',
    'Companionship',
    'Medical Assistance',
    'Housekeeping',
    'Meal Preparation',
    'Personal Care',
    'Respite Care',
    'Live-in Care',
  ];
  
  // Languages Supported
  static const List<String> languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Arabic',
    'Hindi',
    'Urdu',
  ];
  
  // Spacing & Sizing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  
  // Animation Durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);
  
  // Max Content Width (for responsive design)
  static const double maxContentWidth = 1200.0;
  static const double maxMobileWidth = 600.0;
  static const double maxTabletWidth = 900.0;
  
  // Image Placeholders (Using placeholder.com for professional look)
  static const String placeholderHero = 'https://via.placeholder.com/1920x1080/2563EB/FFFFFF?text=CareMatch+Hero';
  static const String placeholderProfile = 'https://via.placeholder.com/400x400/10B981/FFFFFF?text=Profile';
  static const String placeholderService = 'https://via.placeholder.com/600x400/F59E0B/FFFFFF?text=Service';
  static const String placeholderLogo = 'https://via.placeholder.com/200x200/2563EB/FFFFFF?text=CareMatch';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int minBioLength = 50;
  static const int maxBioLength = 500;
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Rating
  static const double maxRating = 5.0;
  static const double minRating = 1.0;
}
