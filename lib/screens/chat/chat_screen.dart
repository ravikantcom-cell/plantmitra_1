// lib/screens/chat/chat_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plantmitra_1/services/chat_service.dart';
import 'package:plantmitra_1/services/public_profile_service.dart';
import 'package:plantmitra_1/utils/logger.dart';

const Color _darkGreen = Color(0xFF174D2B);
const Color _green = Color(0xFF2E7D32);
const Color _secondaryText = Color(0xFF69806E);

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
    this.plantId,
    this.plantName,
    this.plantImage,
    this.chatId,
  });

  final String senderId;
  final String receiverId;
  final String receiverName;
  final String? receiverImage;
  final String? plantId;
  final String? plantName;
  final String? plantImage;
  final String? chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final PublicProfileService _publicProfiles = PublicProfileService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final String _chatId;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isSending = false;
  bool _chatReady = false;
  String? _chatLoadError;
  late String _receiverName;

  @override
  void initState() {
    super.initState();
    _receiverName = widget.receiverName.trim().isEmpty
        ? 'Plant Lover'
        : widget.receiverName.trim();
    _chatId = (widget.chatId ?? '').trim().isNotEmpty
        ? widget.chatId!.trim()
        : _chatService.getChatId(
            widget.senderId,
            widget.receiverId,
            plantId: widget.plantId,
          );
    _focusNode.addListener(_handleFocusChange);
    _loadPublicProfile();
    _prepareChatRoom();
  }

  Future<void> _prepareChatRoom() async {
    if (mounted) setState(() => _chatLoadError = null);
    try {
      await _chatService.ensureChatRoom(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        chatId: _chatId,
        receiverDisplayName: _receiverName,
        plantId: widget.plantId,
        plantName: widget.plantName,
        plantImage: widget.plantImage,
      );
      if (!mounted) return;
      setState(() => _chatReady = true);
      await _markMessagesRead();
    } catch (error) {
      Logger.error('Could not prepare chat room: $error');
      if (!mounted) return;
      setState(() {
        _chatReady = false;
        _chatLoadError = 'Could not connect to this conversation.';
      });
    }
  }

  Future<void> _loadPublicProfile() async {
    await _publicProfiles.ensureCurrentUserProfile();
    final name = await _publicProfiles.getDisplayName(
      widget.receiverId,
      fallback: _receiverName,
    );
    if (mounted && name != _receiverName) {
      setState(() => _receiverName = name);
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _stopTyping();
  }

  Future<void> _markMessagesRead() async {
    await _chatService.markMessagesAsRead(
      chatId: _chatId,
      userId: widget.senderId,
    );
  }

  void _onTextChanged(String value) {
    if (value.trim().isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.setTypingStatus(
        chatId: _chatId,
        userId: widget.senderId,
        isTyping: true,
      );
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (!_isTyping) return;
    _isTyping = false;
    _chatService.setTypingStatus(
      chatId: _chatId,
      userId: widget.senderId,
      isTyping: false,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (!_chatReady) {
      await _prepareChatRoom();
      if (!_chatReady) return;
    }

    setState(() => _isSending = true);
    _messageController.clear();
    _stopTyping();
    try {
      await _chatService.sendMessage(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        text: text,
        plantId: widget.plantId,
        plantName: widget.plantName,
        plantImage: widget.plantImage,
        receiverDisplayName: _receiverName,
        chatId: _chatId,
      );
      _scrollToBottom();
    } catch (error) {
      Logger.error('Sending chat message failed: $error');
      if (mounted) {
        _showMessage(
          'Could not send the message. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _showMessageActions(Map<String, dynamic> message) async {
    final text = message['text']?.toString() ?? '';
    final isMine = message['sender'] == widget.senderId;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: _green),
                title: const Text('Copy message'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Clipboard.setData(ClipboardData(text: text));
                  if (mounted) _showMessage('Message copied.');
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text('Delete message'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteMessage(message['id']?.toString() ?? '');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteMessage(String messageId) async {
    if (messageId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _chatService.deleteMessage(
        chatId: _chatId,
        messageId: messageId,
        userId: widget.senderId,
      );
      if (mounted) _showMessage('Message deleted.');
    } catch (error) {
      Logger.error('Deleting message failed: $error');
      if (mounted) _showMessage('Could not delete the message.', isError: true);
    }
  }

  void _showAttachmentInformation() {
    _showMessage(
      'Image sharing will be available after Firebase Storage is enabled.',
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : _darkGreen,
        ),
      );
  }

  String _messageTime(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _shouldShowDay(List<Map<String, dynamic>> messages, int index) {
    final value = messages[index]['timestamp'];
    if (value is! Timestamp) return false;
    if (index == 0) return true;
    final previous = messages[index - 1]['timestamp'];
    if (previous is! Timestamp) return true;
    final currentDate = value.toDate();
    final previousDate = previous.toDate();
    return currentDate.year != previousDate.year ||
        currentDate.month != previousDate.month ||
        currentDate.day != previousDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.receiverImage?.trim() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE6F4E8),
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? Text(
                      _receiverName.isEmpty
                          ? '?'
                          : _receiverName[0].toUpperCase(),
                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _receiverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!_chatReady)
                    const Text(
                      'Connecting...',
                      style: TextStyle(fontSize: 11, color: _secondaryText),
                    )
                  else
                    StreamBuilder<Map<String, dynamic>>(
                      stream: _chatService.getTypingStatus(chatId: _chatId),
                      builder: (context, snapshot) {
                        final typing =
                            snapshot.data?[widget.receiverId] == true;
                        return Text(
                          typing
                              ? 'typing...'
                              : ((widget.plantName ?? '').trim().isNotEmpty
                                    ? widget.plantName!.trim()
                                    : 'Plant community member'),
                          style: TextStyle(
                            fontSize: 11,
                            color: typing ? _green : _secondaryText,
                            fontWeight: typing
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatReady
                    ? _chatService.getMessagesStream(
                        senderId: widget.senderId,
                        receiverId: widget.receiverId,
                        plantId: widget.plantId,
                        chatId: _chatId,
                      )
                    : null,
                builder: (context, snapshot) {
                  if (!_chatReady) {
                    if (_chatLoadError == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: _green),
                      );
                    }
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: _secondaryText,
                              size: 42,
                            ),
                            const SizedBox(height: 12),
                            Text(_chatLoadError!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _prepareChatRoom,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    Logger.error('Chat messages error: ${snapshot.error}');
                    return const _MessagesErrorView();
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _green),
                    );
                  }
                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return _EmptyConversation(name: _receiverName);
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markMessagesRead();
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message['sender'] == widget.senderId;
                      final timestamp = message['timestamp'];
                      return Column(
                        children: [
                          if (_shouldShowDay(messages, index))
                            _DayDivider(
                              label: timestamp is Timestamp
                                  ? _dayLabel(timestamp.toDate())
                                  : '',
                            ),
                          _MessageBubble(
                            message: message,
                            isMine: isMine,
                            time: _messageTime(timestamp),
                            onLongPress: () => _showMessageActions(message),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        9,
        10,
        9 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E9E1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Attach image',
            onPressed: _isSending ? null : _showAttachmentInformation,
            icon: const Icon(Icons.add_photo_alternate_outlined, color: _green),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: !_isSending,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              onChanged: _onTextChanged,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                filled: true,
                fillColor: const Color(0xFFF2F6F2),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _isSending ? const Color(0xFF9BB69F) : _green,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Send message',
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTyping) {
      _chatService.setTypingStatus(
        chatId: _chatId,
        userId: widget.senderId,
        isTyping: false,
      );
    }
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.time,
    required this.onLongPress,
  });
  final Map<String, dynamic> message;
  final bool isMine;
  final String time;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final text = message['text']?.toString() ?? '';
    final imageUrl = message['imageUrl']?.toString() ?? '';
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 7),
          decoration: BoxDecoration(
            color: isMine ? _green : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 5),
              bottomRight: Radius.circular(isMine ? 5 : 18),
            ),
            border: isMine ? null : Border.all(color: const Color(0xFFE0E9E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 220,
                      height: 120,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
                if (text.isNotEmpty) const SizedBox(height: 7),
              ],
              if (text.isNotEmpty)
                Text(
                  text,
                  style: TextStyle(
                    color: isMine ? Colors.white : const Color(0xFF263B2B),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: isMine ? const Color(0xCFFFFFFF) : _secondaryText,
                      fontSize: 9,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message['read'] == true
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 14,
                      color: message['read'] == true
                          ? const Color(0xFFB9F6CA)
                          : const Color(0xCFFFFFFF),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDDEBDD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _secondaryText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.waving_hand_outlined, color: _green, size: 58),
          const SizedBox(height: 14),
          const Text(
            'Start the conversation',
            style: TextStyle(
              color: _darkGreen,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Say hello to $name.',
            style: const TextStyle(color: _secondaryText),
          ),
        ],
      ),
    ),
  );
}

class _MessagesErrorView extends StatelessWidget {
  const _MessagesErrorView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: Colors.red, size: 54),
          SizedBox(height: 13),
          Text(
            'Could not load messages',
            style: TextStyle(
              color: _darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
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
