import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


import 'package:plantmitra_1/screens/detail/plant_detail_screen.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Plants"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("plants")
            .where("ownerId", isEqualTo: uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You haven't added any plants yet.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final plants = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plants.length,
            itemBuilder: (context, index) {

              final plant =
                  plants[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
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
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),

                  title: Text(
                    plant["name"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        plant["location"] ?? "",
                      ),

                      const SizedBox(height: 5),

                      Text(
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
                    ],
                  ),

                  trailing: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),

                          Text(
                            "${plant["favoriteCount"] ?? 0}",
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          const Icon(
                            Icons.visibility,
                            color: Colors.green,
                            size: 16,
                          ),

                          Text(
                            "${plant["views"] ?? 0}",
                          ),
                        ],
                      ),
                    ],
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlantDetailScreen(
                          documentId: plants[index].id,
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
      ),
    );
  }
}