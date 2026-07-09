import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/chat_service.dart';
import 'package:plantmitra_1/screens/chat/chat_screen.dart';
import 'package:plantmitra_1/screens/auth/login_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  bool _useFallbackQuery = false;
  bool _isInitialized = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checkIndexStatus();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkIndexStatus() async {
    final userId = _chatService.getCurrentUserId();
    if (userId == null) return;

    try {
      final query = _chatService.getUserChatRooms(userId);
      
      _subscription = query.listen((_) {
        if (mounted && !_isInitialized) {
          setState(() {
            _useFallbackQuery = false;
            _isInitialized = true;
          });
        }
        _subscription?.cancel();
      }, onError: (error) {
        if (mounted && !_isInitialized) {
          setState(() {
            _useFallbackQuery = true;
            _isInitialized = true;
          });
        }
        _subscription?.cancel();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _useFallbackQuery = true;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _chatService.getCurrentUserId();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please login to view chats',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _useFallbackQuery 
            ? _chatService.getUserChatRoomsWithoutOrder(userId)
            : _chatService.getUserChatRooms(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading chats...',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            final bool isIndexError = errorMsg.contains('failed-precondition') || 
                                     errorMsg.contains('index');

            if (isIndexError && !_useFallbackQuery) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _useFallbackQuery = true;
                  });
                }
              });
              
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Switching to fallback mode...',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: isIndexError ? Colors.orange : Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isIndexError ? 'Index Required' : 'Error loading chats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isIndexError 
                          ? 'Please wait while the database index is being created.\nThis may take a few minutes.'
                          : snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isIndexError) ...[
                      const Text(
                        '⏳ Index is building. Please wait...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _useFallbackQuery = !_useFallbackQuery;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start chatting with sellers',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!;
          
          if (_useFallbackQuery) {
            chats.sort((a, b) {
              final timeA = a['lastMessageTime'] as Timestamp?;
              final timeB = b['lastMessageTime'] as Timestamp?;
              if (timeA == null && timeB == null) return 0;
              if (timeA == null) return 1;
              if (timeB == null) return -1;
              return timeB.compareTo(timeA);
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = chat['participants'] as List;
              final otherUser = participants.firstWhere(
                (p) => p != userId,
                orElse: () => '',
              );
              
              if (otherUser.isEmpty) return const SizedBox.shrink();

              final lastMessage = chat['lastMessage'] ?? 'No messages yet';
              final lastMessageTime = chat['lastMessageTime'];
              final lastMessageSender = chat['lastMessageSender'];
              final isFromMe = lastMessageSender == userId;
              final chatId = chat['id'] ?? '';

              // Get participant names from chat data or fetch
              final participantsNames = chat['participantsNames'] as Map?;
              String displayName = participantsNames?[otherUser] ?? '';
              
              // If name not in chat data, fetch it
              if (displayName.isEmpty) {
                return FutureBuilder<String>(
                  future: _chatService.getUserDisplayName(otherUser),
                  builder: (context, nameSnapshot) {
                    final name = nameSnapshot.data ?? otherUser.substring(0, 6);
                    return _buildChatItem(
                      chatId: chatId,
                      userId: userId,
                      otherUserId: otherUser,
                      displayName: name,
                      lastMessage: lastMessage,
                      lastMessageTime: lastMessageTime,
                      isFromMe: isFromMe,
                    );
                  },
                );
              }

              return _buildChatItem(
                chatId: chatId,
                userId: userId,
                otherUserId: otherUser,
                displayName: displayName,
                lastMessage: lastMessage,
                lastMessageTime: lastMessageTime,
                isFromMe: isFromMe,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem({
    required String chatId,
    required String userId,
    required String otherUserId,
    required String displayName,
    required String lastMessage,
    required dynamic lastMessageTime,
    required bool isFromMe,
  }) {
    return FutureBuilder<int>(
      future: _getUnreadCount(chatId, userId),
      builder: (context, unreadSnapshot) {
        final unreadCount = unreadSnapshot.data ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    senderId: userId,
                    receiverId: otherUserId,
                    receiverName: displayName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    radius: 28,
                    child: Text(
                      displayName.isNotEmpty 
                          ? displayName.substring(0, 1).toUpperCase() 
                          : '?',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isFromMe)
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.grey,
                              ),
                            if (isFromMe) const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unreadCount > 0 
                                      ? Colors.black 
                                      : Colors.grey.shade600,
                                  fontWeight: unreadCount > 0 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTimestamp(lastMessageTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

  Future<int> _getUnreadCount(String chatId, String userId) async {
    try {
      final snapshot = await _chatService
          .firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('sender', isNotEqualTo: userId)
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return '';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Chats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Implement search logic
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}