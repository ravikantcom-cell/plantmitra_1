import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../detail/plant_detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("favorites")
            .orderBy("createdAt", descending: true)
            .snapshots(),

        builder: (context, favSnapshot) {

          if (favSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!favSnapshot.hasData ||
              favSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Favorite Plants ❤️",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final favDocs = favSnapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
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
                    margin:
                        const EdgeInsets.only(bottom: 12),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),

                    child: ListTile(

                      leading: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(10),

                        child: Image.network(
                          plant["imageUrl"] ?? "",

                          width: 70,
                          height: 70,

                          fit: BoxFit.cover,

                          errorBuilder:
                              (_, __, ___) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade300,
                            child:
                                const Icon(Icons.image),
                          ),
                        ),
                      ),

                      title: Text(
                        plant["name"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        plant["location"] ?? "",
                      ),

                      trailing: Text(
                        plant["isFree"] == true
                            ? "FREE"
                            : "₹ ${plant["price"]}",

                        style: TextStyle(
                          color: plant["isFree"] == true
                              ? Colors.green
                              : Colors.orange,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PlantDetailScreen(
                              documentId:
                                  plantSnapshot.data!.id,

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