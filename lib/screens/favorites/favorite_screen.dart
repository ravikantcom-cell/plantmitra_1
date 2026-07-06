import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../detail/plant_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("favorites")
            .snapshots(),
        builder: (context, favSnapshot) {
          if (!favSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final favDocs = favSnapshot.data!.docs;

          if (favDocs.isEmpty) {
            return const Center(
              child: Text("No Favorite Plants"),
            );
          }

          return ListView.builder(
            itemCount: favDocs.length,
            itemBuilder: (context, index) {
              final plantId = favDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("plants")
                    .doc(plantId)
                    .get(),
                builder: (context, plantSnapshot) {
                  if (!plantSnapshot.hasData) {
                    return const SizedBox();
                  }

                  if (!plantSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final plant = plantSnapshot.data!.data()
                      as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      leading: plant["imageUrl"] != null
                          ? Image.network(
                              plant["imageUrl"],
                              width: 60,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.local_florist),
                      title: Text(plant["name"]),
                      subtitle: Text(plant["location"] ?? ""),
                      trailing: Text(
                        plant["isFree"] == true
                            ? "FREE"
                            : "₹${plant["price"]}",
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlantDetailScreen(
                              documentId: plantId,
                              plant: plant,
                            ),
                          ),
                        );
                      },
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