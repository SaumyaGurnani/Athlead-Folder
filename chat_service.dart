import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'],
      senderId: data['senderId'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
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

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Create or get existing chat room
  Future<ChatRoom> createOrGetChatRoom(String user1Id, String user2Id) async {
    final participants = [user1Id, user2Id]..sort();
    final chatRoomQuery = await _firestore
        .collection('chatRooms')
        .where('participants', isEqualTo: participants)
        .get();

    if (chatRoomQuery.docs.isNotEmpty) {
      return ChatRoom.fromFirestore(chatRoomQuery.docs.first);
    }

    final newChatRoom = ChatRoom(
      id: _uuid.v4(),
      participants: participants,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('chatRooms')
        .doc(newChatRoom.id)
        .set(newChatRoom.toFirestore());

    return newChatRoom;
  }

  // Send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    String? imageUrl,
  }) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(message.id)
        .set(message.toFirestore());

    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message.toFirestore(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get messages stream
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc.data()))
            .toList());
  }

  // Get chat rooms for user
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }

  // Delete chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    // Delete all messages in the chat room
    final messages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .get();

    for (var message in messages.docs) {
      await message.reference.delete();
    }

    // Delete the chat room document
    await _firestore.collection('chatRooms').doc(chatRoomId).delete();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final messages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var message in messages.docs) {
      batch.update(message.reference, {'read': true});
    }
    await batch.commit();
  }
} 