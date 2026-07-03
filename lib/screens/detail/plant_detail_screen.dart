import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../edit_plant/edit_plant_screen.dart';
import '../chat/chat_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> plant;

  const PlantDetailScreen({
    super.key,
    required this.documentId,
    required this.plant,
  });

  Future<void> deletePlant(BuildContext context) async {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == plant["ownerId"];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Plant"),
          content: const Text(
            "Are you sure you want to delete this plant?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
            // Chat button is only shown if NOT the owner
            if (!isOwner)
              const SizedBox(height: 15), // Spacing
            if (!isOwner)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text(
                    "Chat with Owner",
                    style: TextStyle(fontSize: 17),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
  plantId: documentId,
  receiverId: plant["ownerId"],
  receiverName: plant["name"] ?? "",
),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("plants")
          .doc(documentId)
          .delete();

      Fluttertoast.showToast(
        msg: "Plant Deleted Successfully",
      );

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isOwner = user != null && user.uid == plant["ownerId"];

    return Scaffold(
      appBar: AppBar(
        title: Text(plant["name"] ?? "Plant"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Container(
              width: double.infinity,
              height: 260,
              color: Colors.green.shade100,
              child: (plant["imageUrl"] ?? "").toString().isNotEmpty
                  ? Image.network(
                      plant["imageUrl"],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return const Center(
                          child: Icon(
                            Icons.local_florist,
                            size: 120,
                            color: Colors.green,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.local_florist,
                        size: 120,
                        color: Colors.green,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant["name"] ?? "",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plant["location"] ?? "",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plant["description"] ?? "No description available.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      const Text(
                        "Price : ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plant["isFree"] == true
                            ? "FREE 🌱"
                            : "₹ ${plant["price"]}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: plant["isFree"] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Chat button (only for other user's plants)
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.chat),
                        label: const Text(
                          "Chat with Owner",
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
  plantId: documentId,
  receiverId: plant["ownerId"],
  receiverName: plant["name"] ?? "",
),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 35),
                  if (isOwner)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditPlantScreen(
                                    documentId: documentId,
                                    plant: plant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text("Delete"),
                            onPressed: () {
                              deletePlant(context);
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}