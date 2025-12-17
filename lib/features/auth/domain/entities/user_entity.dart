import 'package:equatable/equatable.dart';

/// Pure Dart user entity - NO Firebase/Flutter dependencies
/// Represents a user in the domain layer
abstract class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? phoneCountryCode;
  final String? phoneDialCode;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl;
  final String role; // 'client' or 'caregiver'

  const UserEntity({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.phoneCountryCode,
    this.phoneDialCode,
    required this.isEmailVerified,
    required this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
    required this.role,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        fullName,
        phoneNumber,
        phoneCountryCode,
        phoneDialCode,
        isEmailVerified,
        createdAt,
        updatedAt,
        profileImageUrl,
        role,
      ];
}

/// Client user entity
class ClientUserEntity extends UserEntity {
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;

  const ClientUserEntity({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    super.phoneCountryCode,
    super.phoneDialCode,
    required super.isEmailVerified,
    required super.createdAt,
    super.updatedAt,
    super.profileImageUrl,
    this.address,
    this.city,
    this.state,
    this.zipCode,
  }) : super(role: 'client');

  @override
  List<Object?> get props => [
        ...super.props,
        address,
        city,
        state,
        zipCode,
      ];
}

/// Caregiver user entity
class CaregiverUserEntity extends UserEntity {
  final DateTime dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String? yearsOfExperience;
  final List<String> specializations;
  final String? bio;
  final List<String> certifications;
  final Map<String, dynamic>? availability;
  final String verificationStatus; // 'pending', 'approved', 'rejected'
  final bool documentsSubmitted;
  final String? rejectionReason;

  const CaregiverUserEntity({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phoneNumber,
    super.phoneCountryCode,
    super.phoneDialCode,
    required super.isEmailVerified,
    required super.createdAt,
    super.updatedAt,
    super.profileImageUrl,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.yearsOfExperience,
    this.specializations = const [],
    this.bio,
    this.certifications = const [],
    this.availability,
    this.verificationStatus = 'pending',
    this.documentsSubmitted = false,
    this.rejectionReason,
  }) : super(role: 'caregiver');

  @override
  List<Object?> get props => [
        ...super.props,
        dateOfBirth,
        address,
        city,
        state,
        zipCode,
        yearsOfExperience,
        specializations,
        bio,
        certifications,
        availability,
        verificationStatus,
        documentsSubmitted,
        rejectionReason,
      ];
}
