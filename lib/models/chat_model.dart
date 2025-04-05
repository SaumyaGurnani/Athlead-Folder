import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'],
      chatRoomId: data['chatRoomId'],
      senderId: data['senderId'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'] != null
          ? ChatMessage.fromFirestore(data['lastMessage'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage?.toFirestore(),
    };
  }
} 