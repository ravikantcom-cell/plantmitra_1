import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../edit_plant/edit_plant_screen.dart';
class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Plants")),
        body: const Center(child: Text("Please login")),
      );
    }

    debugPrint("🔍 DEBUG: Fetching plants for UID: ${user.uid}");

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Plants"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("plants")
            .where("ownerId", isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("❌ ERROR: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final plants = snapshot.data!.docs;

          debugPrint("📊 DEBUG: Total Plants Found: ${plants.length}");
          for (var doc in plants) {
            debugPrint("🌿 Plant: ${doc['name']} | UID: ${doc.id} | CreatedAt: ${doc['createdAt']}");
          }

          if (plants.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_florist, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No plants found yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final doc = plants[index];
              final plantData = doc.data() as Map<String, dynamic>;
              
              // Format timestamp nicely
              String formattedDate = "Added today";
              if (plantData['createdAt'] is Timestamp) {
                formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(
                  plantData['createdAt'].toDate()
                );
              } else if (plantData['createdAt'] != null) {
                formattedDate = plantData['createdAt'].toString();
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plantData['name'] ?? "Unknown Plant",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (plantData['type'] != null)
                        Text(
                          "Type: ${plantData['type']}",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        "Added: $formattedDate",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Navigate to edit screen with document ID
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPlantScreen(
                                    documentId: doc.id,
                                    plant: plantData,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text("Edit"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}