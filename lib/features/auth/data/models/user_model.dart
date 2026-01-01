import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Client user model - extends entity and adds Firebase serialization
class ClientUserModel extends ClientUserEntity {
  const ClientUserModel({
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
    super.address,
    super.city,
    super.state,
    super.zipCode,
  });

  /// Convert entity to model
  factory ClientUserModel.fromEntity(ClientUserEntity entity) {
    return ClientUserModel(
      uid: entity.uid,
      email: entity.email,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      phoneCountryCode: entity.phoneCountryCode,
      phoneDialCode: entity.phoneDialCode,
      isEmailVerified: entity.isEmailVerified,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      profileImageUrl: entity.profileImageUrl,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      zipCode: entity.zipCode,
    );
  }

  /// Create from Firestore document
  factory ClientUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientUserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      phoneCountryCode: data['phoneCountryCode'],
      phoneDialCode: data['phoneDialCode'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
      profileImageUrl: data['profileImageUrl'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
    );
  }

  /// Create from JSON map
  factory ClientUserModel.fromJson(Map<String, dynamic> json) {
    return ClientUserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      phoneCountryCode: json['phoneCountryCode'],
      phoneDialCode: json['phoneDialCode'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
      profileImageUrl: json['profileImageUrl'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'phoneCountryCode': phoneCountryCode,
      'phoneDialCode': phoneDialCode,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'role': 'client',
    };
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'phoneCountryCode': phoneCountryCode,
      'phoneDialCode': phoneDialCode,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'role': 'client',
    };
  }

  /// Helper to parse DateTime from Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}

/// Caregiver user model - extends entity and adds Firebase serialization
class CaregiverUserModel extends CaregiverUserEntity {
  const CaregiverUserModel({
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
    required super.dateOfBirth,
    required super.address,
    required super.city,
    required super.state,
    required super.zipCode,
    super.yearsOfExperience,
    super.specializations = const [],
    super.bio,
    super.certifications = const [],
    super.availability,
    super.verificationStatus = 'pending',
    super.documentsSubmitted = false,
    super.rejectionReason,
  });

  /// Convert entity to model
  factory CaregiverUserModel.fromEntity(CaregiverUserEntity entity) {
    return CaregiverUserModel(
      uid: entity.uid,
      email: entity.email,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      phoneCountryCode: entity.phoneCountryCode,
      phoneDialCode: entity.phoneDialCode,
      isEmailVerified: entity.isEmailVerified,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      profileImageUrl: entity.profileImageUrl,
      dateOfBirth: entity.dateOfBirth,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      zipCode: entity.zipCode,
      yearsOfExperience: entity.yearsOfExperience,
      specializations: entity.specializations,
      bio: entity.bio,
      certifications: entity.certifications,
      availability: entity.availability,
      verificationStatus: entity.verificationStatus,
      documentsSubmitted: entity.documentsSubmitted,
      rejectionReason: entity.rejectionReason,
    );
  }

  /// Create from Firestore document
  factory CaregiverUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaregiverUserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      phoneCountryCode: data['phoneCountryCode'],
      phoneDialCode: data['phoneDialCode'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
      profileImageUrl: data['profileImageUrl'],
      dateOfBirth: _parseDateTime(data['dateOfBirth']),
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      yearsOfExperience: data['yearsOfExperience'],
      specializations: List<String>.from(data['specializations'] ?? []),
      bio: data['bio'],
      certifications: List<String>.from(data['certifications'] ?? []),
      availability: data['availability'],
      verificationStatus: data['verificationStatus'] ?? 'pending',
      documentsSubmitted: data['documentsSubmitted'] ?? false,
      rejectionReason: data['rejectionReason'],
    );
  }

  /// Create from JSON map
  factory CaregiverUserModel.fromJson(Map<String, dynamic> json) {
    return CaregiverUserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      phoneCountryCode: json['phoneCountryCode'],
      phoneDialCode: json['phoneDialCode'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
      profileImageUrl: json['profileImageUrl'],
      dateOfBirth: _parseDateTime(json['dateOfBirth']),
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      yearsOfExperience: json['yearsOfExperience'],
      specializations: List<String>.from(json['specializations'] ?? []),
      bio: json['bio'],
      certifications: List<String>.from(json['certifications'] ?? []),
      availability: json['availability'],
      verificationStatus: json['verificationStatus'] ?? 'pending',
      documentsSubmitted: json['documentsSubmitted'] ?? false,
      rejectionReason: json['rejectionReason'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'phoneCountryCode': phoneCountryCode,
      'phoneDialCode': phoneDialCode,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'profileImageUrl': profileImageUrl,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'yearsOfExperience': yearsOfExperience,
      'specializations': specializations,
      'bio': bio,
      'certifications': certifications,
      'availability': availability,
      'verificationStatus': verificationStatus,
      'documentsSubmitted': documentsSubmitted,
      'rejectionReason': rejectionReason,
      'role': 'caregiver',
    };
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'phoneCountryCode': phoneCountryCode,
      'phoneDialCode': phoneDialCode,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'yearsOfExperience': yearsOfExperience,
      'specializations': specializations,
      'bio': bio,
      'certifications': certifications,
      'availability': availability,
      'verificationStatus': verificationStatus,
      'documentsSubmitted': documentsSubmitted,
      'rejectionReason': rejectionReason,
      'role': 'caregiver',
    };
  }

  /// Helper to parse DateTime from Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}
