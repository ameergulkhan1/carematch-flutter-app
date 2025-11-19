import 'package:cloud_firestore/cloud_firestore.dart';

/// Caregiver User Model
class CaregiverUser {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  
  // Professional Information
  final String? yearsOfExperience;
  final List<String> specializations;
  final String? bio;
  final List<String> certifications;
  
  // Verification Status
  final String verificationStatus; // 'pending', 'approved', 'rejected'
  final bool isEmailVerified;
  final bool documentsSubmitted;
  
  // Documents (Firebase Storage URLs)
  final Map<String, String> documents; // {type: url}
  // Document types: 'id_proof', 'address_proof', 'certifications', 'background_check'
  
  // Metadata
  final String role; // 'caregiver'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionReason;

  CaregiverUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.yearsOfExperience,
    this.specializations = const [],
    this.bio,
    this.certifications = const [],
    this.verificationStatus = 'pending',
    this.isEmailVerified = false,
    this.documentsSubmitted = false,
    this.documents = const {},
    this.role = 'caregiver',
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'yearsOfExperience': yearsOfExperience,
      'specializations': specializations,
      'bio': bio,
      'certifications': certifications,
      'verificationStatus': verificationStatus,
      'isEmailVerified': isEmailVerified,
      'documentsSubmitted': documentsSubmitted,
      'documents': documents,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rejectionReason': rejectionReason,
    };
  }

  // Create from Firestore
  factory CaregiverUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaregiverUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      yearsOfExperience: data['yearsOfExperience'],
      specializations: List<String>.from(data['specializations'] ?? []),
      bio: data['bio'],
      certifications: List<String>.from(data['certifications'] ?? []),
      verificationStatus: data['verificationStatus'] ?? 'pending',
      isEmailVerified: data['isEmailVerified'] ?? false,
      documentsSubmitted: data['documentsSubmitted'] ?? false,
      documents: Map<String, String>.from(data['documents'] ?? {}),
      role: data['role'] ?? 'caregiver',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  // Copy with
  CaregiverUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? yearsOfExperience,
    List<String>? specializations,
    String? bio,
    List<String>? certifications,
    String? verificationStatus,
    bool? isEmailVerified,
    bool? documentsSubmitted,
    Map<String, String>? documents,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rejectionReason,
  }) {
    return CaregiverUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      specializations: specializations ?? this.specializations,
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      documentsSubmitted: documentsSubmitted ?? this.documentsSubmitted,
      documents: documents ?? this.documents,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

/// Document Upload Model
class DocumentUpload {
  final String documentType;
  final String fileName;
  final String? filePath;
  final DateTime uploadedAt;
  final String status; // 'pending', 'verified', 'rejected'

  DocumentUpload({
    required this.documentType,
    required this.fileName,
    this.filePath,
    required this.uploadedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'documentType': documentType,
      'fileName': fileName,
      'filePath': filePath,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'status': status,
    };
  }
}
