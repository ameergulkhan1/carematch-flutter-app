import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../../../models/chat_model.dart';
import 'chat_conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.getChatList(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with caregivers',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatItem(chat);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    final otherUserName = chat.getOtherParticipantName(_currentUserId);
    final otherUserImage = chat.getOtherParticipantImage(_currentUserId);
    final unreadCount = chat.getUnreadCount(_currentUserId);
    final isUnread = unreadCount > 0;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.teal[100],
            backgroundImage: otherUserImage != null
                ? NetworkImage(otherUserImage)
                : null,
            child: otherUserImage == null
                ? Text(
                    otherUserName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, color: Colors.teal),
                  )
                : null,
          ),
          if (isUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUserName,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
          if (chat.lastMessageTime != null)
            Text(
              _formatTimestamp(chat.lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: isUnread ? Colors.teal : Colors.grey[600],
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: chat.lastMessage != null
          ? Row(
              children: [
                if (chat.lastMessageSenderId == _currentUserId)
                  const Icon(Icons.done_all, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    chat.lastMessage!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      color: isUnread ? Colors.black87 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              chatId: chat.id,
              otherUserName: otherUserName,
              otherUserImage: otherUserImage,
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('h:mm a').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(timestamp);
    } else {
      // Older - show date
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
