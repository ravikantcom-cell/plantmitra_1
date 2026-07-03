import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("users", arrayContains: uid)
            .orderBy("lastTime", descending: true)
            .snapshots(),
                    builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Chats Yet",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final chat =
                  docs[index].data() as Map<String, dynamic>;

              final users =
                  List<String>.from(chat["users"]);

              final receiverId =
                  users.firstWhere((e) => e != uid);

              return ListTile(

                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.local_florist,
                    color: Colors.white,
                  ),
                ),

                title: Text(
                  chat["plantId"] ?? "Plant",
                ),

                subtitle: Text(
                  chat["lastMessage"] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),

                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        plantId: chat["plantId"],
                        receiverId: receiverId,
                        receiverName: "User",
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}