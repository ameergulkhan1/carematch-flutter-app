import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../models/chat_model.dart';
import '../../../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Create a new chat or get existing chat between two users
  Future<String> createOrGetChat({
    required String userId1,
    required String userId2,
    required String user1Name,
    required String user2Name,
    String? user1Image,
    String? user2Image,
    String? bookingId,
  }) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(userId2)) {
          return doc.id;
        }
      }

      // Create new chat
      final chatData = ChatModel(
        id: '',
        participants: [userId1, userId2],
        participantNames: {
          userId1: user1Name,
          userId2: user2Name,
        },
        participantImages: {
          if (user1Image != null) userId1: user1Image,
          if (user2Image != null) userId2: user2Image,
        },
        unreadCount: {
          userId1: 0,
          userId2: 0,
        },
        bookingId: bookingId,
        createdAt: DateTime.now(),
      );

      final chatRef = await _firestore.collection('chats').add(chatData.toMap());
      
      // Send system message
      await sendSystemMessage(
        chatId: chatRef.id,
        text: 'Chat started',
      );

      return chatRef.id;
    } catch (e) {
      print('❌ Error creating/getting chat: $e');
      rethrow;
    }
  }

  /// Get all chats for a user (real-time stream)
  Stream<List<ChatModel>> getChatList(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get messages for a chat (real-time stream)
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Load last 100 messages
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required String text,
  }) async {
    try {
      final message = MessageModel.text(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        text: text,
      );

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update chat with last message
      await _updateChatLastMessage(
        chatId: chatId,
        message: text,
        senderId: senderId,
      );
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Send an image message
  Future<void> sendImage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Upload image to Firebase Storage
      final fileName = 'chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      final message = MessageModel.image(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        imageUrl: imageUrl,
        caption: caption,
      );

      // Add message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update chat
      await _updateChatLastMessage(
        chatId: chatId,
        message: caption != null ? '📷 $caption' : '📷 Photo',
        senderId: senderId,
      );
    } catch (e) {
      print('❌ Error sending image: $e');
      rethrow;
    }
  }

  /// Send a file message
  Future<void> sendFile({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required File file,
    required String fileName,
  }) async {
    try {
      // Upload file to Firebase Storage
      final storagePath = 'chat_files/$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = _storage.ref().child(storagePath);
      await ref.putFile(file);
      final fileUrl = await ref.getDownloadURL();

      final message = MessageModel.file(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        fileName: fileName,
        fileUrl: fileUrl,
      );

      // Add message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update chat
      await _updateChatLastMessage(
        chatId: chatId,
        message: '📎 $fileName',
        senderId: senderId,
      );
    } catch (e) {
      print('❌ Error sending file: $e');
      rethrow;
    }
  }

  /// Send a hire request message
  Future<void> sendHireRequest({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderImage,
    required String bookingId,
    required Map<String, dynamic> bookingDetails,
  }) async {
    try {
      final message = MessageModel.hireRequest(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        bookingId: bookingId,
        bookingDetails: bookingDetails,
      );

      // Add message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update chat with booking ID
      await _firestore.collection('chats').doc(chatId).update({
        'bookingId': bookingId,
        'lastMessage': '💼 Hire request sent',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });

      // Increment unread count for other participant
      await _incrementUnreadCount(chatId, senderId);
    } catch (e) {
      print('❌ Error sending hire request: $e');
      rethrow;
    }
  }

  /// Send a system message
  Future<void> sendSystemMessage({
    required String chatId,
    required String text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = MessageModel.system(
        chatId: chatId,
        text: text,
        metadata: metadata,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      print('❌ Error sending system message: $e');
    }
  }

  /// Mark all messages as read for a user
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Get unread messages
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('readBy.$userId', isEqualTo: null)
          .get();

      // Update each message
      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {
          'readBy.$userId': true,
        });
      }
      await batch.commit();

      // Reset unread count
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Get unread message count for a user across all chats
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        total += (unreadCount?[userId] as int?) ?? 0;
      }
      return total;
    });
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Mark as inactive instead of deleting
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
      });
    } catch (e) {
      print('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  /// Private helper: Update chat's last message
  Future<void> _updateChatLastMessage({
    required String chatId,
    required String message,
    required String senderId,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });

      // Increment unread count for other participant
      await _incrementUnreadCount(chatId, senderId);
    } catch (e) {
      print('❌ Error updating last message: $e');
    }
  }

  /// Private helper: Increment unread count for other participant
  Future<void> _incrementUnreadCount(String chatId, String senderId) async {
    try {
      final chat = await _firestore.collection('chats').doc(chatId).get();
      final participants = List<String>.from(chat.data()?['participants'] ?? []);
      final otherUserId = participants.firstWhere((id) => id != senderId);

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Error incrementing unread count: $e');
    }
  }
}
