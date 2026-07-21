// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantmitra_1/utils/logger.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firestore;

  List<String> _participants(String user1, String user2) {
    return <String>[user1, user2]..sort();
  }

  String getChatId(String user1, String user2, {String? plantId}) {
    final ids = _participants(user1, user2);
    final cleanPlantId = (plantId ?? '').trim().replaceAll('/', '_');
    if (cleanPlantId.isEmpty) return '${ids[0]}_${ids[1]}';
    return '${cleanPlantId}__${ids[0]}_${ids[1]}';
  }

  String? getCurrentUserId() => FirebaseAuth.instance.currentUser?.uid;
  User? getCurrentUser() => FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore
          .collection('public_profiles')
          .doc(userId)
          .get();
      return doc.exists
          ? <String, dynamic>{'id': doc.id, ...?doc.data()}
          : null;
    } catch (error) {
      Logger.error('Error getting public user info: $error');
      return null;
    }
  }

  final Map<String, String> _userNameCache = <String, String>{};

  Future<String> getUserDisplayName(String userId) async {
    final cached = _userNameCache[userId];
    if (cached != null) return cached;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == userId) {
      final name = currentUser?.displayName?.trim().isNotEmpty == true
          ? currentUser!.displayName!.trim()
          : currentUser?.email?.split('@').first ?? 'You';
      _userNameCache[userId] = name;
      return name;
    }
    final info = await getUserInfo(userId);
    final name = (info?['displayName'] ?? 'Plant Lover').toString().trim();
    _userNameCache[userId] = name.isEmpty ? 'Plant Lover' : name;
    return _userNameCache[userId]!;
  }

  Future<void> ensureChatRoom({
    required String senderId,
    required String receiverId,
    String? chatId,
    String? receiverDisplayName,
    String? plantId,
    String? plantName,
    String? plantImage,
  }) async {
    final resolvedChatId = (chatId ?? '').trim().isNotEmpty
        ? chatId!.trim()
        : getChatId(senderId, receiverId, plantId: plantId);
    final senderName = await getUserDisplayName(senderId);
    final suppliedName = receiverDisplayName?.trim() ?? '';
    final receiverName = suppliedName.isNotEmpty
        ? suppliedName
        : await getUserDisplayName(receiverId);

    await _firestore.collection('chats').doc(resolvedChatId).set(
      <String, dynamic>{
        'participants': _participants(senderId, receiverId),
        'participantsNames': <String, String>{
          senderId: senderName,
          receiverId: receiverName,
        },
        'plantId': plantId ?? '',
        'plantName': plantName ?? 'Plant listing',
        'plantImage': plantImage ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String? plantId,
    String? plantName,
    String? plantImage,
    String? receiverDisplayName,
    String? chatId,
  }) async {
    if (text.trim().isEmpty) return;
    final resolvedChatId = (chatId ?? '').trim().isNotEmpty
        ? chatId!.trim()
        : getChatId(senderId, receiverId, plantId: plantId);
    final chatRef = _firestore.collection('chats').doc(resolvedChatId);
    final senderName = await getUserDisplayName(senderId);
    final suppliedReceiverName = receiverDisplayName?.trim() ?? '';
    final receiverName = suppliedReceiverName.isNotEmpty
        ? suppliedReceiverName
        : await getUserDisplayName(receiverId);

    await chatRef.set(<String, dynamic>{
      'participants': _participants(senderId, receiverId),
      'participantsNames': <String, String>{
        senderId: senderName,
        receiverId: receiverName,
      },
      'plantId': plantId ?? '',
      'plantName': plantName ?? 'Plant listing',
      'plantImage': plantImage ?? '',
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': senderId,
      'lastMessageType': 'text',
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add(<String, dynamic>{
      'sender': senderId,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'plantId': plantId ?? '',
    });
  }

  Future<void> sendImage({
    required String senderId,
    required String receiverId,
    required String imageUrl,
    String? plantId,
    String? plantName,
    String? plantImage,
    String? receiverDisplayName,
    String? chatId,
  }) async {
    final resolvedChatId = (chatId ?? '').trim().isNotEmpty
        ? chatId!.trim()
        : getChatId(senderId, receiverId, plantId: plantId);
    final chatRef = _firestore.collection('chats').doc(resolvedChatId);
    final senderName = await getUserDisplayName(senderId);
    final suppliedReceiverName = receiverDisplayName?.trim() ?? '';
    final receiverName = suppliedReceiverName.isNotEmpty
        ? suppliedReceiverName
        : await getUserDisplayName(receiverId);
    await chatRef.set(<String, dynamic>{
      'participants': _participants(senderId, receiverId),
      'participantsNames': <String, String>{
        senderId: senderName,
        receiverId: receiverName,
      },
      'plantId': plantId ?? '',
      'plantName': plantName ?? 'Plant listing',
      'plantImage': plantImage ?? '',
      'lastMessage': 'Image',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': senderId,
      'lastMessageType': 'image',
    }, SetOptions(merge: true));
    await chatRef.collection('messages').add(<String, dynamic>{
      'sender': senderId,
      'type': 'image',
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'plantId': plantId ?? '',
    });
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream({
    required String senderId,
    required String receiverId,
    String? plantId,
    String? chatId,
  }) {
    final resolvedChatId = (chatId ?? '').trim().isNotEmpty
        ? chatId!.trim()
        : getChatId(senderId, receiverId, plantId: plantId);
    return _firestore
        .collection('chats')
        .doc(resolvedChatId)
        .collection('messages')
        .orderBy('timestamp')
        .limitToLast(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required String senderId,
    required String receiverId,
    String? plantId,
    String? chatId,
  }) async {
    final resolvedChatId = (chatId ?? '').trim().isNotEmpty
        ? chatId!.trim()
        : getChatId(senderId, receiverId, plantId: plantId);
    final snapshot = await _firestore
        .collection('chats')
        .doc(resolvedChatId)
        .collection('messages')
        .orderBy('timestamp')
        .limitToLast(100)
        .get();
    return snapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
  }

  Stream<List<Map<String, dynamic>>> getUserChatRooms(String userId) =>
      _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
                .toList(),
          );

  Stream<List<Map<String, dynamic>>> getUserChatRoomsWithoutOrder(
    String userId,
  ) => _firestore
      .collection('chats')
      .where('participants', arrayContains: userId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList(),
      );

  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    var changed = false;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['sender'] != userId && data['read'] != true) {
        batch.update(doc.reference, <String, dynamic>{'read': true});
        changed = true;
      }
    }
    if (changed) await batch.commit();
  }

  Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) => _firestore.collection('chats').doc(chatId).set(<String, dynamic>{
    'typing': <String, dynamic>{
      userId: isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    },
  }, SetOptions(merge: true));

  Stream<Map<String, dynamic>> getTypingStatus({required String chatId}) =>
      _firestore
          .collection('chats')
          .doc(chatId)
          .snapshots()
          .map(
            (doc) => Map<String, dynamic>.from(
              doc.data()?['typing'] ?? <String, dynamic>{},
            ),
          );

  Future<int> getUnreadCount(String userId) async {
    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();
    var count = 0;
    for (final chat in chats.docs) {
      final messages = await chat.reference.collection('messages').get();
      count += messages.docs.where((doc) {
        final data = doc.data();
        return data['sender'] != userId && data['read'] != true;
      }).length;
    }
    return count;
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    final ref = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    final doc = await ref.get();
    if (doc.data()?['sender'] == userId) await ref.delete();
  }

  Future<void> deleteChat({
    required String chatId,
    required String userId,
  }) async {
    final ref = _firestore.collection('chats').doc(chatId);
    final chat = await ref.get();
    if (!(List<String>.from(
      chat.data()?['participants'] ?? <String>[],
    )).contains(userId))
      return;
    final messages = await ref.collection('messages').get();
    final batch = _firestore.batch();
    for (final message in messages.docs) {
      batch.delete(message.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getChatInfo(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.exists ? <String, dynamic>{'id': doc.id, ...?doc.data()} : null;
  }

  Future<bool> chatExists(String chatId) async =>
      (await _firestore.collection('chats').doc(chatId).get()).exists;
}
