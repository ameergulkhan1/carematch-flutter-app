import 'package:cloud_firestore/cloud_firestore.dart';

class ClientUser {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? phoneCountryCode; // e.g., 'US', 'GB', 'IN'
  final String? phoneDialCode;    // e.g., '+1', '+44', '+91'
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
    this.phoneCountryCode,
    this.phoneDialCode,
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
      'phoneCountryCode': phoneCountryCode,
      'phoneDialCode': phoneDialCode,
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
      phoneCountryCode: data['phoneCountryCode'],
      phoneDialCode: data['phoneDialCode'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // Helper to parse DateTime from Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now();
    }
  }

  // Copy with method for updates
  ClientUser copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? phoneCountryCode,
    String? phoneDialCode,
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
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneDialCode: phoneDialCode ?? this.phoneDialCode,
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
