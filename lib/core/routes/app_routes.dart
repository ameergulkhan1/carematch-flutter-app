/// CareMatch App Routes
/// Centralized route management
class AppRoutes {
  // Landing & Public Pages
  static const String landing = '/';
  static const String whatWeOffer = '/what-we-offer';
  static const String howItWorks = '/how-it-works';
  static const String serviceTypes = '/service-types';
  static const String pricing = '/pricing';
  static const String faq = '/faq';
  
  // Authentication
  static const String login = '/login';
  static const String signupClient = '/signup-client';
  static const String signupCaregiver = '/signup-caregiver';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String verifyOtp = '/verify-otp';
  
  // Client Routes
  static const String clientDashboard = '/client/dashboard';
  static const String clientProfile = '/client/profile';
  static const String createCarePlan = '/client/care-plan/create';
  static const String editCarePlan = '/client/care-plan/edit';
  static const String searchCaregiver = '/client/search-caregiver';
  static const String caregiverDetail = '/client/caregiver-detail';
  static const String clientBookings = '/client/bookings';
  static const String clientBookingDetail = '/client/booking-detail';
  static const String clientChat = '/client/chat';
  static const String clientPayments = '/client/payments';
  static const String clientReviews = '/client/reviews';
  
  // Caregiver Routes
  static const String caregiverDashboard = '/caregiver/dashboard';
  static const String caregiverProfile = '/caregiver/profile';
  static const String caregiverOnboarding = '/caregiver/onboarding';
  static const String caregiverVerification = '/caregiver/verification';
  static const String caregiverServices = '/caregiver/services';
  static const String caregiverAvailability = '/caregiver/availability';
  static const String caregiverBookings = '/caregiver/bookings';
  static const String caregiverBookingDetail = '/caregiver/booking-detail';
  static const String caregiverEarnings = '/caregiver/earnings';
  static const String caregiverChat = '/caregiver/chat';
  static const String caregiverReviews = '/caregiver/reviews';
  
  // Shared Routes
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String termsOfService = '/terms';
  static const String privacyPolicy = '/privacy';
  static const String contactUs = '/contact';
}
