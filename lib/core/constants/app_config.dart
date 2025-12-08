/// Application Configuration Constants
class AppConfig {
  // EmailJS Configuration for OTP
  // To enable email OTP:
  // 1. Go to https://www.emailjs.com/ and sign up
  // 2. Create an email service
  // 3. Create a template with these variables: {{to_email}}, {{to_name}}, {{otp_code}}, {{expiry_minutes}}, {{app_name}}
  // 4. Get your Public Key from Account page
  // 5. Add your template ID and public key below
  
  static const String emailJsServiceId = 'service_22itnmx';
  static const String emailJsTemplateId = 'template_carematch_otp'; // Update with your template ID
  static const String emailJsPublicKey = 'YOUR_PUBLIC_KEY_HERE'; // Add your EmailJS public key here
  
  // NOTE: If emailJsPublicKey is empty, OTP will only be printed to console
  // For testing, check the browser console or terminal for the OTP code
  
  // OTP Configuration
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;
  
  // App Configuration
  static const String appName = 'CareMatch';
  static const String supportEmail = 'support@carematch.com';
  static const String termsUrl = 'https://carematch.com/terms';
  static const String privacyUrl = 'https://carematch.com/privacy';
}
