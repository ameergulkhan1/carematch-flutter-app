import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat conversation model
class ChatModel {
  final String id;
  final List<String> participants; // [clientId, caregiverId]
  final Map<String, String> participantNames; // {userId: name}
  final Map<String, String>? participantImages; // {userId: imageUrl}
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // {userId: count}
  final String? bookingId; // Optional - if chat is related to a booking
  final DateTime createdAt;
  final bool isActive;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantImages,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.bookingId,
    required this.createdAt,
    this.isActive = true,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantImages: map['participantImages'] != null
          ? Map<String, String>.from(map['participantImages'])
          : null,
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      bookingId: map['bookingId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'bookingId': bookingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId);
  }

  /// Get the other participant's name
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Get the other participant's image
  String? getOtherParticipantImage(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantImages?[otherId];
  }

  /// Get unread count for current user
  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }

  ChatModel copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
  }) {
    return ChatModel(
      id: id,
      participants: participants,
      participantNames: participantNames,
      participantImages: participantImages,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      bookingId: bookingId,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
