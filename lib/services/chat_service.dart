import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public getter for firestore
  FirebaseFirestore get firestore => _firestore;

  // 🔥 PUBLIC method to get chat ID
  String getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // 👤 Get current user ID
  String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // 👤 Get current user
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // 📋 Get user info by ID with better error handling
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // 📋 Get user display name with fallback
  final Map<String, String> _userNameCache = {};

  Future<String> getUserDisplayName(String userId) async {
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final userInfo = await getUserInfo(userId);
      
      String name;
      if (userInfo != null) {
        name = userInfo['displayName'] ?? 
               userInfo['name'] ?? 
               userInfo['username'] ?? 
               userInfo['email']?.split('@').first ??
               'User';
      } else {
        // Check if it's the current user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          name = currentUser.displayName ?? 
                 currentUser.email?.split('@').first ?? 
                 'You';
        } else {
          // Fallback: use the ID but format it nicely
          name = userId.length > 8 ? userId.substring(0, 8) : userId;
        }
      }
      
      // Cache the name
      _userNameCache[userId] = name;
      return name;
    } catch (e) {
      print('Error getting user name: $e');
      // Return a formatted ID as fallback
      return userId.length > 8 ? userId.substring(0, 8) : userId;
    }
  }

  // 📨 Send text message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final chatId = getChatId(senderId, receiverId);
      
      final chatRef = _firestore.collection('chats').doc(chatId);

      await chatRef
          .collection('messages')
          .add({
        'sender': senderId,
        'text': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Get sender name for better display
      final senderName = await getUserDisplayName(senderId);
      final receiverName = await getUserDisplayName(receiverId);

      await chatRef.set({
        'participants': [senderId, receiverId],
        'participantsNames': {
          senderId: senderName,
          receiverId: receiverName,
        },
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'lastMessageType': 'text',
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // 🖼️ Send image message
  Future<void> sendImage({
    required String senderId,
    required String receiverId,
    required String imageUrl,
  }) async {
    try {
      final chatId = getChatId(senderId, receiverId);
      final chatRef = _firestore.collection('chats').doc(chatId);

      await chatRef.collection('messages').add({
        'sender': senderId,
        'type': 'image',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await chatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': '📷 Image',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'lastMessageType': 'image',
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending image: $e');
      rethrow;
    }
  }

  // 📥 Real-time messages stream
  Stream<List<Map<String, dynamic>>> getMessagesStream({
    required String senderId,
    required String receiverId,
  }) {
    try {
      final chatId = getChatId(senderId, receiverId);

      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limitToLast(50)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
          });
    } catch (e) {
      print('Error getting messages stream: $e');
      return Stream.value([]);
    }
  }

  // 📤 Get all messages (one-time)
  Future<List<Map<String, dynamic>>> getMessages({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final chatId = getChatId(senderId, receiverId);

      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limitToLast(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // 📋 Get all chat rooms for a user
  Stream<List<Map<String, dynamic>>> getUserChatRooms(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
          });
    } catch (e) {
      print('Error getting chat rooms: $e');
      return Stream.error(e);
    }
  }

  // 📋 Get chat rooms without ordering (fallback)
  Stream<List<Map<String, dynamic>>> getUserChatRoomsWithoutOrder(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
          });
    } catch (e) {
      print('Error getting chat rooms without order: $e');
      return Stream.error(e);
    }
  }

  // ✅ Mark messages as read - Fixed with index warning handling
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      // First try to get unread messages
      final messagesRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('sender', isNotEqualTo: userId)
          .where('read', isEqualTo: false);

      final snapshot = await messagesRef.get();
      
      if (snapshot.docs.isEmpty) return;
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      // If index is missing, try without the read filter
      try {
        final messagesRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('sender', isNotEqualTo: userId);

        final snapshot = await messagesRef.get();
        
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['read'] == false) {
            batch.update(doc.reference, {'read': true});
          }
        }
        await batch.commit();
      } catch (e2) {
        print('Error in fallback mark messages as read: $e2');
      }
    }
  }

  // 📝 Update typing status
  Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'typing': {
          userId: isTyping,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }

  // 🔄 Get typing status
  Stream<Map<String, dynamic>> getTypingStatus({
    required String chatId,
  }) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .snapshots()
          .map((doc) {
            final data = doc.data();
            if (data == null) return {};
            return data['typing'] ?? {};
          });
    } catch (e) {
      print('Error getting typing status: $e');
      return Stream.value({});
    }
  }

  // 📊 Get unread message count
  Future<int> getUnreadCount(String userId) async {
    try {
      final chats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (var chat in chats.docs) {
        try {
          final snapshot = await chat.reference
              .collection('messages')
              .where('sender', isNotEqualTo: userId)
              .where('read', isEqualTo: false)
              .count()
              .get();
          totalUnread += snapshot.count ?? 0;
        } catch (e) {
          print('Error counting unread for chat ${chat.id}: $e');
          // Fallback: count manually
          try {
            final allMessages = await chat.reference
                .collection('messages')
                .where('sender', isNotEqualTo: userId)
                .get();
            int unread = 0;
            for (var doc in allMessages.docs) {
              if (doc.data()['read'] == false) {
                unread++;
              }
            }
            totalUnread += unread;
          } catch (e2) {
            print('Error in fallback unread count: $e2');
          }
        }
      }
      return totalUnread;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // 🗑️ Delete a message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      
      final doc = await messageRef.get();
      if (doc.exists && doc.data()?['sender'] == userId) {
        await messageRef.delete();
      }
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // 🗑️ Delete entire chat
  Future<void> deleteChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (chatDoc.exists && (chatDoc.data()?['participants'] as List).contains(userId)) {
        // Delete all messages
        final messages = await chatRef.collection('messages').get();
        final batch = _firestore.batch();
        for (var doc in messages.docs) {
          batch.delete(doc.reference);
        }
        batch.delete(chatRef);
        await batch.commit();
      }
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  // 🔍 Get chat info
  Future<Map<String, dynamic>?> getChatInfo(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Error getting chat info: $e');
      return null;
    }
  }

  // 🔍 Check if chat exists
  Future<bool> chatExists(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking chat exists: $e');
      return false;
    }
  }
}