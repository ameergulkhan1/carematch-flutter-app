import 'package:cloud_firestore/cloud_firestore.dart';

class ClientUser {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl;

  ClientUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.isEmailVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'profileImageUrl': profileImageUrl,
      'role': 'client',
    };
  }

  // Create from Firestore document
  factory ClientUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'],
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // Copy with method for updates
  ClientUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
  }) {
    return ClientUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
