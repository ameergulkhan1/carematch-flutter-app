/// Application-wide configuration constants
/// Contains app metadata, business rules, and feature flags
class AppConfig {
  // ==================== APP METADATA ====================

  /// Application name
  static const String appName = 'CareMatch';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Build number
  static const int buildNumber = 1;

  /// Package name
  static const String packageName = 'com.carematch.app';

  /// Company/Organization name
  static const String companyName = 'CareMatch Inc.';

  /// Support email
  static const String supportEmail = 'support@carematch.com';

  /// Privacy policy URL
  static const String privacyPolicyUrl = 'https://carematch.com/privacy';

  /// Terms of service URL
  static const String termsOfServiceUrl = 'https://carematch.com/terms';

  // ==================== FEATURE FLAGS ====================

  /// Enable chat feature
  static const bool enableChat = true;

  /// Enable video call feature
  static const bool enableVideoCall = false; // Coming soon

  /// Enable voice call feature
  static const bool enableVoiceCall = false; // Coming soon

  /// Enable payment integration
  static const bool enablePayments = true;

  /// Enable wallet feature
  static const bool enableWallet = true;

  /// Enable in-app notifications
  static const bool enableInAppNotifications = true;

  /// Enable push notifications
  static const bool enablePushNotifications = true;

  /// Enable SMS notifications
  static const bool enableSmsNotifications = false; // Premium feature

  /// Enable email notifications
  static const bool enableEmailNotifications = true;

  /// Enable location tracking during sessions
  static const bool enableLocationTracking = true;

  /// Enable background location (when app is closed)
  static const bool enableBackgroundLocation = false;

  /// Enable biometric authentication
  static const bool enableBiometric = true;

  /// Enable social login (Google, Facebook, Apple)
  static const bool enableSocialLogin = false; // Coming soon

  /// Enable ratings and reviews
  static const bool enableReviews = true;

  /// Enable referral system
  static const bool enableReferrals = false; // Coming soon

  /// Enable promotional banners
  static const bool enablePromotionalBanners = true;

  // ==================== PAGINATION ====================

  /// Default page size for lists
  static const int pageSize = 20;

  /// Maximum items to load at once
  static const int maxPageSize = 100;

  /// Infinite scroll threshold (load more when this % from bottom)
  static const double infiniteScrollThreshold = 0.8;

  // ==================== FILE UPLOAD LIMITS ====================

  /// Maximum file size for uploads (in MB)
  static const int maxUploadSizeMB = 5;

  /// Maximum file size in bytes
  static const int maxUploadSizeBytes = maxUploadSizeMB * 1024 * 1024;

  /// Allowed image formats
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Allowed document formats
  static const List<String> allowedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
  ];

  /// Maximum profile photo size (in MB)
  static const int maxProfilePhotoSizeMB = 2;

  /// Maximum document count per upload
  static const int maxDocumentsPerUpload = 4;

  // ==================== VALIDATION RULES ====================

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum password length
  static const int maxPasswordLength = 64;

  /// Minimum age requirement
  static const int minAge = 18;

  /// Maximum age allowed
  static const int maxAge = 100;

  /// Phone number minimum length (including country code)
  static const int minPhoneLength = 10;

  /// Phone number maximum length
  static const int maxPhoneLength = 15;

  /// Bio/description maximum length
  static const int maxBioLength = 500;

  /// Review maximum length
  static const int maxReviewLength = 1000;

  /// Minimum hourly rate (in USD)
  static const double minHourlyRate = 10.0;

  /// Maximum hourly rate (in USD)
  static const double maxHourlyRate = 200.0;

  // ==================== BOOKING RULES ====================

  /// Minimum booking duration (in hours)
  static const int minBookingDurationHours = 2;

  /// Maximum booking duration (in hours)
  static const int maxBookingDurationHours = 24;

  /// Maximum advance booking (in days)
  static const int maxAdvanceBookingDays = 90;

  /// Minimum notice for booking (in hours)
  static const int minBookingNoticeHours = 24;

  /// Cancellation window (in hours before start)
  static const int cancellationWindowHours = 24;

  /// Auto-cancel if not accepted within (hours)
  static const int autoRejectAfterHours = 48;

  // ==================== PAYMENT CONFIGURATION ====================

  /// Platform fee percentage (charged to clients)
  static const double platformFeePercentage = 15.0;

  /// Currency code
  static const String currencyCode = 'USD';

  /// Currency symbol
  static const String currencySymbol = '\$';

  /// Minimum payment amount
  static const double minPaymentAmount = 20.0;

  /// Maximum single transaction amount
  static const double maxTransactionAmount = 10000.0;

  /// Minimum wallet top-up amount
  static const double minWalletTopUp = 10.0;

  /// Maximum wallet balance
  static const double maxWalletBalance = 50000.0;

  /// Payout processing time (in business days)
  static const int payoutProcessingDays = 3;

  // ==================== RATING & REVIEW ====================

  /// Minimum rating (stars)
  static const int minRating = 1;

  /// Maximum rating (stars)
  static const int maxRating = 5;

  /// Minimum rating to show caregiver
  static const double minDisplayRating = 3.0;

  /// Minimum number of reviews to show average
  static const int minReviewsForAverage = 5;

  // ==================== SESSION MANAGEMENT ====================

  /// Session timeout (minutes of inactivity)
  static const int sessionTimeoutMinutes = 30;

  /// Token refresh interval (minutes)
  static const int tokenRefreshMinutes = 50;

  /// Remember me duration (days)
  static const int rememberMeDays = 30;

  // ==================== NOTIFICATION SETTINGS ====================

  /// Notification check interval (minutes)
  static const int notificationCheckMinutes = 5;

  /// Maximum notifications to show at once
  static const int maxNotificationsDisplay = 50;

  /// Notification retention days
  static const int notificationRetentionDays = 30;

  // ==================== CACHE SETTINGS ====================

  /// Cache size limit (in MB)
  static const int maxCacheSizeMB = 100;

  /// Profile cache duration (hours)
  static const int profileCacheHours = 24;

  /// Search results cache duration (minutes)
  static const int searchCacheMinutes = 30;

  /// Image cache duration (days)
  static const int imageCacheDays = 7;

  // ==================== MAP & LOCATION ====================

  /// Default map zoom level
  static const double defaultMapZoom = 12.0;

  /// Maximum search radius (in kilometers)
  static const double maxSearchRadiusKm = 50.0;

  /// Default search radius (in kilometers)
  static const double defaultSearchRadiusKm = 10.0;

  /// Location update interval during session (seconds)
  static const int locationUpdateIntervalSeconds = 30;

  // ==================== RATE LIMITING ====================

  /// Maximum login attempts before lockout
  static const int maxLoginAttempts = 5;

  /// Account lockout duration (minutes)
  static const int lockoutDurationMinutes = 15;

  /// Maximum search queries per minute
  static const int maxSearchQueriesPerMinute = 10;

  /// Maximum booking requests per day
  static const int maxBookingRequestsPerDay = 20;

  // ==================== UI CONFIGURATION ====================

  /// Animation duration (milliseconds)
  static const int animationDurationMs = 300;

  /// Debounce duration for search (milliseconds)
  static const int searchDebounceDurationMs = 500;

  /// Snackbar display duration (seconds)
  static const int snackbarDurationSeconds = 3;

  /// Toast message duration (seconds)
  static const int toastDurationSeconds = 2;

  /// Splash screen minimum duration (seconds)
  static const int splashScreenDurationSeconds = 2;

  // ==================== ADMIN CONFIGURATION ====================

  /// Maximum users per admin dashboard page
  static const int adminUsersPageSize = 50;

  /// Verification document review timeout (days)
  static const int verificationTimeoutDays = 7;

  /// Dispute resolution timeout (days)
  static const int disputeResolutionDays = 14;

  // ==================== SERVICE TYPES ====================

  /// Available service types
  static const List<String> serviceTypes = [
    'Personal Care',
    'Companionship',
    'Meal Preparation',
    'Light Housekeeping',
    'Transportation',
    'Medication Reminders',
    'Grocery Shopping',
    'Pet Care',
    'Respite Care',
    'Specialized Care',
  ];

  /// Maximum service types per caregiver
  static const int maxServiceTypesPerCaregiver = 5;

  // ==================== HELPER METHODS ====================

  /// Get platform fee amount from total
  static double calculatePlatformFee(double amount) {
    return amount * (platformFeePercentage / 100);
  }

  /// Get caregiver earnings after platform fee
  static double calculateCaregiverEarnings(double amount) {
    return amount - calculatePlatformFee(amount);
  }

  /// Check if file size is within limit
  static bool isFileSizeValid(int sizeInBytes) {
    return sizeInBytes <= maxUploadSizeBytes;
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Get app version string
  static String get fullVersion => '$appVersion+$buildNumber';

  /// Print configuration summary
  static void printSummary() {
    print('');
    print('════════════════════════════════════════');
    print('  $appName v$fullVersion');
    print('════════════════════════════════════════');
    print('Chat: ${enableChat ? '✅' : '❌'}');
    print('Video Call: ${enableVideoCall ? '✅' : '❌'}');
    print('Payments: ${enablePayments ? '✅' : '❌'}');
    print('Location Tracking: ${enableLocationTracking ? '✅' : '❌'}');
    print('Push Notifications: ${enablePushNotifications ? '✅' : '❌'}');
    print('Platform Fee: $platformFeePercentage%');
    print('Currency: $currencyCode ($currencySymbol)');
    print('════════════════════════════════════════');
    print('');
  }
}
