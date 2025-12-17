import 'package:equatable/equatable.dart';

/// Authentication credentials for signing in
class SignInCredentials extends Equatable {
  final String email;
  final String password;

  const SignInCredentials({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Registration credentials for client signup
class ClientSignUpCredentials extends Equatable {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String? phoneCountryCode;
  final String? phoneDialCode;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;

  const ClientSignUpCredentials({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    this.phoneCountryCode,
    this.phoneDialCode,
    this.address,
    this.city,
    this.state,
    this.zipCode,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        fullName,
        phoneNumber,
        phoneCountryCode,
        phoneDialCode,
        address,
        city,
        state,
        zipCode,
      ];
}

/// Registration credentials for caregiver signup
class CaregiverSignUpCredentials extends Equatable {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String? phoneCountryCode;
  final String? phoneDialCode;
  final DateTime dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String? yearsOfExperience;
  final List<String> specializations;
  final String? bio;

  const CaregiverSignUpCredentials({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    this.phoneCountryCode,
    this.phoneDialCode,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.yearsOfExperience,
    this.specializations = const [],
    this.bio,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        fullName,
        phoneNumber,
        phoneCountryCode,
        phoneDialCode,
        dateOfBirth,
        address,
        city,
        state,
        zipCode,
        yearsOfExperience,
        specializations,
        bio,
      ];
}

/// OTP verification credentials
class OTPCredentials extends Equatable {
  final String email;
  final String otp;

  const OTPCredentials({
    required this.email,
    required this.otp,
  });

  @override
  List<Object?> get props => [email, otp];
}

/// Password reset credentials
class PasswordResetCredentials extends Equatable {
  final String email;

  const PasswordResetCredentials({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}
