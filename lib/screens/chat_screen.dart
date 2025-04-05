import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chat_service.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  ChatRoom? _chatRoom;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser!;
    _chatRoom = await _chatService.createOrGetChatRoom(
      currentUser.id,
      widget.otherUser.id,
    );
    setState(() {});
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatRoom == null) return;

    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser!;
    await _chatService.sendMessage(
      chatRoomId: _chatRoom!.id,
      senderId: currentUser.id,
      content: _messageController.text.trim(),
    );

    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && _chatRoom != null) {
      setState(() => _isLoading = true);
      
      try {
        final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser!;
        // TODO: Upload image to Firebase Storage and get URL
        await _chatService.sendMessage(
          chatRoomId: _chatRoom!.id,
          senderId: currentUser.id,
          content: '📷 Image',
          imageUrl: 'TODO: Add image URL',
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show user profile or chat info
            },
          ),
        ],
      ),
      body: _chatRoom == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.getMessages(_chatRoom!.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final messages = snapshot.data!;
                      final currentUser = Provider.of<UserProvider>(context).currentUser!;

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser.id;

                          return _MessageBubble(
                            message: message,
                            isMe: isMe,
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: _isLoading ? null : _sendImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 