import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';

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
      chatRoomId: chatRoomId,
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