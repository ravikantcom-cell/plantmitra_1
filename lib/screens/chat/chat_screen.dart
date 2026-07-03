import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantmitra/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String plantId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.plantId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController =
      TextEditingController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return;

      final messages = await _chatService.getMessages(
        currentUser.uid,
        widget.receiverId,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final text = _messageController.text.trim();

    _messageController.clear();

    await _chatService.sendMessage(
      currentUser.uid,
      widget.receiverId,
      text,
    );

    setState(() {
      _messages.add({
        "sender": currentUser.uid,
        "text": text,
        "timestamp": DateTime.now(),
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];

                      final isMe =
                          msg["sender"] == currentUser?.uid;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.green
                                : Colors.grey.shade300,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg["text"],
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: "Type message...",
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(25),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.green,
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: _sendMessage,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}