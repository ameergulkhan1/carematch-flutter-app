/// Admin Route Constants
class AdminRoutes {
  // Base admin route
  static const String admin = '/admin';
  
  // Admin authentication
  static const String adminLogin = '/admin/login';
  
  // Admin dashboard
  static const String adminDashboard = '/admin/dashboard';
  
  // User management
  static const String adminUsers = '/admin/users';
  static const String adminUserDetails = '/admin/users/:id';
  
  // Caregiver management
  static const String adminCaregivers = '/admin/caregivers';
  static const String adminCaregiverDetails = '/admin/caregivers/:id';
  
  // Verification requests
  static const String adminVerifications = '/admin/verifications';
  static const String adminVerificationDetails = '/admin/verifications/:id';
  
  // Document management
  static const String adminDocuments = '/admin/documents';
  static const String adminDocumentView = '/admin/documents/:id';
  
  // Bookings management
  static const String adminBookings = '/admin/bookings';
  static const String adminBookingDetails = '/admin/bookings/:id';
  
  // Analytics
  static const String adminAnalytics = '/admin/analytics';
  
  // Settings
  static const String adminSettings = '/admin/settings';
  
  // Helper methods for navigation
  static String getUserDetailsRoute(String userId) {
    return adminUserDetails.replaceFirst(':id', userId);
  }
  
  static String getCaregiverDetailsRoute(String caregiverId) {
    return adminCaregiverDetails.replaceFirst(':id', caregiverId);
  }
  
  static String getVerificationDetailsRoute(String requestId) {
    return adminVerificationDetails.replaceFirst(':id', requestId);
  }
  
  static String getDocumentViewRoute(String documentId) {
    return adminDocumentView.replaceFirst(':id', documentId);
  }
  
  static String getBookingDetailsRoute(String bookingId) {
    return adminBookingDetails.replaceFirst(':id', bookingId);
  }
}
