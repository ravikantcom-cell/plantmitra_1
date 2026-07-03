import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../add_plant/add_plant_screen.dart';
import '../detail/plant_detail_screen.dart';
import '../../services/favorite_service.dart';

final FavoriteService favoriteService = FavoriteService();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌱 PlantMitra"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Plant"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPlantScreen(),
            ),
          );
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              decoration: InputDecoration(
                hintText: "Search plants...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("plants")
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
                      child: Text("No Plants Found"),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final name = (data["name"] ?? "")
                        .toString()
                        .toLowerCase();

                    return name.contains(searchText);
                  }).toList();

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {

                      final plant =
                          docs[index].data() as Map<String, dynamic>;

                      return PlantCard(
                        plantId: docs[index].id,
                        plant: plant,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlantDetailScreen(
                                documentId: docs[index].id,
                                plant: plant,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,
        type: BottomNavigationBarType.fixed,
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
class PlantCard extends StatelessWidget {
  final String plantId;
  final Map<String, dynamic> plant;
  final VoidCallback onTap;

  const PlantCard({
    super.key,
    required this.plantId,
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = plant["name"] ?? "Unknown Plant";
    final String location = plant["location"] ?? "";
    final String imageUrl = plant["imageUrl"] ?? "";
    final bool isFree = plant["isFree"] ?? true;
    final int price = (plant["price"] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.green.shade100,
                          child: const Icon(
                            Icons.eco,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.green.shade100,
                        child: const Icon(
                          Icons.eco,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(location),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isFree ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isFree ? "FREE" : "₹ $price",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              StreamBuilder<bool>(
  stream: favoriteService.isFavorite(plantId),
  builder: (context, snapshot) {
    final isFavorite = snapshot.data ?? false;

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey,
      ),
      onPressed: () async {
        await favoriteService.toggleFavorite(plantId);
      },
    );
  },
),
            ],
          ),
        ),
      ),
    );
  }
}