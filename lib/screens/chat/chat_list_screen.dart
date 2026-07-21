// lib/screens/chat/chat_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/screens/chat/chat_screen.dart';
import 'package:plantmitra_1/services/chat_service.dart';
import 'package:plantmitra_1/services/public_profile_service.dart';
import 'package:plantmitra_1/utils/logger.dart';

const Color _darkGreen = Color(0xFF174D2B);
const Color _green = Color(0xFF2E7D32);
const Color _secondaryText = Color(0xFF69806E);

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final PublicProfileService _publicProfiles = PublicProfileService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _publicProfiles.ensureCurrentUserProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _sortedChats(List<Map<String, dynamic>> source) {
    final chats = source.toList();
    chats.sort((a, b) {
      final aValue = a['lastMessageTime'];
      final bValue = b['lastMessageTime'];
      final aTime = aValue is Timestamp ? aValue.millisecondsSinceEpoch : 0;
      final bTime = bValue is Timestamp ? bValue.millisecondsSinceEpoch : 0;
      return bTime.compareTo(aTime);
    });
    return chats;
  }

  String _otherUserId(Map<String, dynamic> chat, String currentUserId) {
    final participants = chat['participants'];
    if (participants is! List) return '';
    for (final participant in participants) {
      final id = participant?.toString() ?? '';
      if (id.isNotEmpty && id != currentUserId) return id;
    }
    return '';
  }

  String _displayName(Map<String, dynamic> chat, String otherUserId) {
    final names = chat['participantsNames'];
    if (names is Map) {
      final name = names[otherUserId]?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    return otherUserId.length > 8 ? otherUserId.substring(0, 8) : otherUserId;
  }

  String _chatPreview(Map<String, dynamic> chat) {
    final plantName = chat['plantName']?.toString().trim() ?? '';
    final message = chat['lastMessage']?.toString().trim() ?? '';
    if (plantName.isNotEmpty && message.isNotEmpty) {
      return '$plantName · $message';
    }
    if (plantName.isNotEmpty) return plantName;
    return message.isNotEmpty ? message : 'No messages yet';
  }

  List<Map<String, dynamic>> _visibleChats(
    List<Map<String, dynamic>> chats,
    String currentUserId,
  ) {
    if (_query.isEmpty) return chats;
    return chats.where((chat) {
      final otherId = _otherUserId(chat, currentUserId);
      final name = _displayName(chat, otherId).toLowerCase();
      final lastMessage = chat['lastMessage']?.toString().toLowerCase() ?? '';
      return name.contains(_query) || lastMessage.contains(_query);
    }).toList();
  }

  Future<void> _openChat({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
    required String displayName,
    String? plantId,
    String? plantName,
    String? plantImage,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          senderId: currentUserId,
          receiverId: otherUserId,
          receiverName: displayName,
          chatId: chatId,
          plantId: plantId,
          plantName: plantName,
          plantImage: plantImage,
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final days = today.difference(messageDay).inDays;
    if (days == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
    }
    if (days == 1) return 'Yesterday';
    if (days < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.getCurrentUserId();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
      ),
      body: currentUserId == null
          ? const _SignedOutView()
          : StreamBuilder<List<Map<String, dynamic>>>(
              // Local sorting avoids a composite Firestore index requirement.
              stream: _chatService.getUserChatRoomsWithoutOrder(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const _LoadingView();
                }
                if (snapshot.hasError) {
                  Logger.error('Chat list stream error: ${snapshot.error}');
                  return const _ErrorView();
                }
                final allChats = _sortedChats(snapshot.data ?? const []);
                if (allChats.isEmpty) return const _EmptyChatsView();
                final visibleChats = _visibleChats(allChats, currentUserId);

                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _ChatHeaderCard(count: allChats.length),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      sliver: SliverToBoxAdapter(child: _buildSearch()),
                    ),
                    if (visibleChats.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoResultsView(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        sliver: SliverList.separated(
                          itemCount: visibleChats.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final chat = visibleChats[index];
                            final otherId = _otherUserId(chat, currentUserId);
                            if (otherId.isEmpty) return const SizedBox.shrink();
                            final fallbackName = _displayName(chat, otherId);
                            return FutureBuilder<String>(
                              future: _publicProfiles.getDisplayName(
                                otherId,
                                fallback: fallbackName,
                              ),
                              initialData: fallbackName,
                              builder: (context, nameSnapshot) {
                                final name = nameSnapshot.data ?? fallbackName;
                                return _ChatTile(
                                  chatId: chat['id']?.toString() ?? '',
                                  currentUserId: currentUserId,
                                  displayName: name,
                                  lastMessage: _chatPreview(chat),
                                  time: _formatTime(chat['lastMessageTime']),
                                  sentByMe:
                                      chat['lastMessageSender'] ==
                                      currentUserId,
                                  firestore: _chatService.firestore,
                                  onTap: () => _openChat(
                                    chatId: chat['id']?.toString() ?? '',
                                    currentUserId: currentUserId,
                                    otherUserId: otherId,
                                    displayName: name,
                                    plantId: chat['plantId']?.toString(),
                                    plantName: chat['plantName']?.toString(),
                                    plantImage: chat['plantImage']?.toString(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search conversations',
        prefixIcon: const Icon(Icons.search_rounded, color: _green),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDE7DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _green, width: 1.6),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chatId,
    required this.currentUserId,
    required this.displayName,
    required this.lastMessage,
    required this.time,
    required this.sentByMe,
    required this.firestore,
    required this.onTap,
  });

  final String chatId;
  final String currentUserId;
  final String displayName;
  final String lastMessage;
  final String time;
  final bool sentByMe;
  final FirebaseFirestore firestore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (chatId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unread =
            snapshot.data?.docs.where((document) {
              return document.data()['sender'] != currentUserId;
            }).length ??
            0;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFE0E9E1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE6F4E8),
                    child: Text(
                      displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: _green,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _darkGreen,
                            fontSize: 16,
                            fontWeight: unread > 0
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (sentByMe) ...[
                              const Icon(
                                Icons.done_rounded,
                                size: 15,
                                color: _secondaryText,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Expanded(
                              child: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread > 0
                                      ? const Color(0xFF334638)
                                      : _secondaryText,
                                  fontSize: 13,
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: unread > 0 ? _green : _secondaryText,
                          fontSize: 10,
                          fontWeight: unread > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (unread > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatHeaderCard extends StatelessWidget {
  const _ChatHeaderCard({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_darkGreen, _green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(Icons.forum_rounded, color: Colors.white, size: 35),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plant conversations',
                style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? 'conversation' : 'conversations'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: _green));
}

class _EmptyChatsView extends StatelessWidget {
  const _EmptyChatsView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: _green, size: 72),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              color: _darkGreen,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Open a plant listing and contact its owner to start chatting.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText),
          ),
        ],
      ),
    ),
  );
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'No matching conversations found.',
      style: TextStyle(color: _secondaryText),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red, size: 56),
          SizedBox(height: 13),
          Text(
            'Could not load chats',
            style: TextStyle(
              color: _darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Please check your connection and Firestore permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText),
          ),
        ],
      ),
    ),
  );
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (route) => false),
      child: const Text('Sign in to view chats'),
    ),
  );
}
