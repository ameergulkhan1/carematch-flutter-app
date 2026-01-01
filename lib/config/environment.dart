/// Application environment configuration
/// Controls which environment the app is running in and provides
/// environment-specific configurations like API endpoints and Firebase projects
enum Environment {
  /// Development environment - for local development and testing
  development,

  /// Staging environment - for QA and pre-production testing
  staging,

  /// Production environment - for live users
  production,
}

/// Environment configuration manager
/// Provides environment-specific settings and feature flags
class EnvironmentConfig {
  /// Current environment - defaults to development
  /// Set this in main.dart before running the app
  static Environment _currentEnvironment = Environment.development;

  /// Get the current environment
  static Environment get environment => _currentEnvironment;

  /// Set the current environment
  /// Should be called in main.dart before runApp()
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  /// Check if running in development
  static bool get isDevelopment => _currentEnvironment == Environment.development;

  /// Check if running in staging
  static bool get isStaging => _currentEnvironment == Environment.staging;

  /// Check if running in production
  static bool get isProduction => _currentEnvironment == Environment.production;

  // ==================== API CONFIGURATION ====================

  /// Base URL for REST API (if using)
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'https://dev-api.carematch.com/v1';
      case Environment.staging:
        return 'https://staging-api.carematch.com/v1';
      case Environment.production:
        return 'https://api.carematch.com/v1';
    }
  }

  /// WebSocket URL (for real-time features)
  static String get websocketUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'wss://dev-ws.carematch.com';
      case Environment.staging:
        return 'wss://staging-ws.carematch.com';
      case Environment.production:
        return 'wss://ws.carematch.com';
    }
  }

  // ==================== FIREBASE CONFIGURATION ====================

  /// Firebase project ID for the current environment
  static String get firebaseProjectId {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'carematch-dev';
      case Environment.staging:
        return 'carematch-staging';
      case Environment.production:
        return 'flowing-bazaar-468814-g0'; // Your production project
    }
  }

  /// Firebase auth domain
  static String get firebaseAuthDomain {
    return '$firebaseProjectId.firebaseapp.com';
  }

  /// Firebase storage bucket
  static String get firebaseStorageBucket {
    return '$firebaseProjectId.firebasestorage.app';
  }

  // ==================== LOGGING & DEBUGGING ====================

  /// Enable verbose logging
  static bool get enableLogging {
    return _currentEnvironment != Environment.production;
  }

  /// Enable debug features
  static bool get enableDebugFeatures {
    return _currentEnvironment == Environment.development;
  }

  /// Enable error reporting (Crashlytics, Sentry, etc.)
  static bool get enableErrorReporting {
    return _currentEnvironment == Environment.production;
  }

  /// Enable performance monitoring
  static bool get enablePerformanceMonitoring {
    return _currentEnvironment == Environment.production ||
        _currentEnvironment == Environment.staging;
  }

  // ==================== PAYMENT CONFIGURATION ====================

  /// Stripe publishable key
  static String get stripePublishableKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'pk_test_development_key'; // Test key
      case Environment.staging:
        return 'pk_test_staging_key'; // Test key
      case Environment.production:
        return 'pk_live_production_key'; // Live key
    }
  }

  /// Stripe secret key (server-side only)
  /// This should not be in the client app - just for reference
  static String get stripeSecretKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'sk_test_development_key';
      case Environment.staging:
        return 'sk_test_staging_key';
      case Environment.production:
        return 'sk_live_production_key';
    }
  }

  /// Use Stripe test mode
  static bool get useStripeTestMode {
    return _currentEnvironment != Environment.production;
  }

  // ==================== GOOGLE MAPS CONFIGURATION ====================

  /// Google Maps API key
  static String get googleMapsApiKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'YOUR_DEV_GOOGLE_MAPS_KEY';
      case Environment.staging:
        return 'YOUR_STAGING_GOOGLE_MAPS_KEY';
      case Environment.production:
        return 'YOUR_PROD_GOOGLE_MAPS_KEY';
    }
  }

  // ==================== THIRD-PARTY SERVICES ====================

  /// Twilio Account SID (for SMS)
  static String get twilioAccountSid {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'AC_dev_account_sid';
      case Environment.staging:
        return 'AC_staging_account_sid';
      case Environment.production:
        return 'AC_prod_account_sid';
    }
  }

  /// Sentry DSN (for error tracking)
  static String get sentryDsn {
    switch (_currentEnvironment) {
      case Environment.development:
        return ''; // Empty in dev - no reporting
      case Environment.staging:
        return 'https://staging@sentry.io/project';
      case Environment.production:
        return 'https://production@sentry.io/project';
    }
  }

  // ==================== TIMEOUTS & LIMITS ====================

  /// API request timeout
  static Duration get apiTimeout {
    return const Duration(seconds: 30);
  }

  /// Upload timeout for large files
  static Duration get uploadTimeout {
    return const Duration(minutes: 5);
  }

  /// Session timeout (inactivity)
  static Duration get sessionTimeout {
    return const Duration(minutes: 30);
  }

  /// Cache duration for API responses
  static Duration get cacheExpiration {
    switch (_currentEnvironment) {
      case Environment.development:
        return const Duration(minutes: 1); // Short cache in dev
      case Environment.staging:
        return const Duration(minutes: 5);
      case Environment.production:
        return const Duration(minutes: 15);
    }
  }

  // ==================== ENVIRONMENT INFO ====================

  /// Get environment name as string
  static String get environmentName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Get environment display name with emoji
  static String get environmentDisplayName {
    switch (_currentEnvironment) {
      case Environment.development:
        return '🔧 Development';
      case Environment.staging:
        return '🧪 Staging';
      case Environment.production:
        return '🚀 Production';
    }
  }

  /// Print current environment configuration
  static void printConfig() {
    if (!enableLogging) return;

    print('');
    print('════════════════════════════════════════');
    print('  CAREMATCH ENVIRONMENT CONFIG');
    print('════════════════════════════════════════');
    print('Environment: $environmentDisplayName');
    print('API Base URL: $apiBaseUrl');
    print('Firebase Project: $firebaseProjectId');
    print('Logging Enabled: $enableLogging');
    print('Debug Features: $enableDebugFeatures');
    print('Error Reporting: $enableErrorReporting');
    print('════════════════════════════════════════');
    print('');
  }
}
