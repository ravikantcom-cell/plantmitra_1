import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get messages between two users
  Future<List<Map<String, dynamic>>> getMessages(
    String userId1,
    String userId2,
  ) async {
    // Create a unique chat room ID (sorted to ensure same ID for both users)
    final chatId = userId1.compareTo(userId2) < 0
        ? '$userId1-$userId2'
        : '$userId2-$userId1';

    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => {
                'sender': doc['sender'],
                'text': doc['text'],
                'timestamp': (doc['timestamp'] as Timestamp).toDate(),
              })
          .toList();
    } catch (e) {
      print("Error getting messages: $e");
      return [];
    }
  }

  /// Send a message
  Future<void> sendMessage(
    String senderId,
    String recipientId,
    String message,
  ) async {
    try {
      final chatId = senderId.compareTo(recipientId) < 0
          ? '$senderId-$recipientId'
          : '$recipientId-$senderId';

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'sender': senderId,
        'recipient': recipientId,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  /// Create a new chat room
  Future<void> createChatRoom(String userId1, String userId2) async {
    try {
      final chatId = userId1.compareTo(userId2) < 0
          ? '$userId1-$userId2'
          : '$userId2-$userId1';

      await _firestore.collection('chats').doc(chatId).set({
        'userId1': userId1,
        'userId2': userId2,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating chat room: $e");
    }
  }
}