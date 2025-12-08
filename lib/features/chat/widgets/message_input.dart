import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/chat_service.dart';

class MessageInput extends StatefulWidget {
  final String chatId;
  final VoidCallback? onMessageSent;

  const MessageInput({
    super.key,
    required this.chatId,
    this.onMessageSent,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSending = false;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String _senderName = '';
  String? _senderImage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _senderName = data['name'] ?? 'Unknown';
          _senderImage = data['profileImage'];
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _senderName = 'User';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Colors.grey[700],
            onPressed: _isSending ? null : _showAttachmentOptions,
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Update send button state
              },
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          _isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _controller.text.trim().isEmpty
                        ? Icons.mic
                        : Icons.send,
                  ),
                  color: Colors.teal,
                  onPressed: _controller.text.trim().isEmpty
                      ? null // Voice message functionality can be added later
                      : _sendMessage,
                ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                title: const Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isSending) return;

    final text = _controller.text.trim();
    _controller.clear();

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: _currentUserId,
        senderName: _senderName,
        senderImage: _senderImage,
        text: text,
      );

      widget.onMessageSent?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
      // Restore text if failed
      _controller.text = text;
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _sendImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _sendImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _sendImage(File imageFile) async {
    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendImage(
        chatId: widget.chatId,
        senderId: _currentUserId,
        senderName: _senderName,
        senderImage: _senderImage,
        imageFile: imageFile,
      );

      widget.onMessageSent?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        setState(() {
          _isSending = true;
        });

        try {
          await _chatService.sendFile(
            chatId: widget.chatId,
            senderId: _currentUserId,
            senderName: _senderName,
            senderImage: _senderImage,
            file: file,
            fileName: fileName,
          );

          widget.onMessageSent?.call();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File sent')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send file: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isSending = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }
}
