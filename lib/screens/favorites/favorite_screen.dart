import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/screens/detail/plant_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Check if user is logged in
  bool get _isLoggedIn => _auth.currentUser != null;
  String get _userId => _auth.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    // Handle not logged in
    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Favorites"),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                "Please login to see your favorites",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Login to save and view your favorite plants",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Clear all favorites button
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(_userId)
                .collection("favorites")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearFavoritesDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(_userId)
            .collection("favorites")
            .orderBy("addedAt", descending: true)
            .snapshots(),
        builder: (context, favSnapshot) {
          // Loading state
          if (favSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading favorites...",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Error state
          if (favSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade300,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading favorites",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    favSnapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (!favSnapshot.hasData || favSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No Favorite Plants ❤️",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Start adding plants to your favorites!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Data loaded - show favorites
          final favDocs = favSnapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favDocs.length,
            itemBuilder: (context, index) {
              final plantId = favDocs[index].id;
              final favData = favDocs[index].data() as Map<String, dynamic>;
              final addedAt = favData['addedAt'] as Timestamp?;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("plants")
                    .doc(plantId)
                    .get(),
                builder: (context, plantSnapshot) {
                  // Loading plant details
                  if (plantSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    child: Text("Loading..."),
                                  ),
                                  SizedBox(height: 8),
                                  SizedBox(
                                    height: 16,
                                    width: 100,
                                    child: Text(""),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Plant not found or deleted
                  if (!plantSnapshot.hasData || 
                      !plantSnapshot.data!.exists || 
                      plantSnapshot.data == null) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Plant no longer available",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "This plant has been removed",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _removeFavorite(plantId);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Valid plant - display
                  final plant = plantSnapshot.data!.data() as Map<String, dynamic>;
                  final isFree = plant["isFree"] ?? false;
                  final price = plant["price"] ?? 0;
                  final name = plant["name"] ?? "Unknown Plant";
                  final location = plant["location"] ?? "Location not specified";
                  final imageUrl = plant["imageUrl"] ?? "";
                  final category = plant["category"] ?? "";
                  final itemType = plant["itemType"] ?? "Plant";
                  final favoriteCount = plant["favoriteCount"] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlantDetailScreen(
                              documentId: plantSnapshot.data!.id,
                              plant: plant,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade100,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.green,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.local_florist,
                                          color: Colors.green,
                                          size: 35,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.green.shade100,
                                      child: const Icon(
                                        Icons.local_florist,
                                        color: Colors.green,
                                        size: 35,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 15),

                            // Plant Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  
                                  // Category & Item Type
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      if (category.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          itemType,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Location
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Price & Stats
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isFree ? Colors.green : Colors.orange,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isFree ? "FREE" : "₹ $price",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            "$favoriteCount",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      if (addedAt != null)
                                        Text(
                                          _formatDate(addedAt.toDate()),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Remove favorite button
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                _removeFavorite(plantId);
                              },
                            ),
                          ],
                        ),
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

  // Remove a single favorite
  Future<void> _removeFavorite(String plantId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_userId)
          .collection("favorites")
          .doc(plantId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from favorites"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error removing favorite: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clear all favorites confirmation
  void _showClearFavoritesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Favorites"),
        content: const Text(
          "Are you sure you want to remove all plants from your favorites?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final batch = FirebaseFirestore.instance.batch();
                final snapshot = await FirebaseFirestore.instance
                    .collection("users")
                    .doc(_userId)
                    .collection("favorites")
                    .get();
                
                for (var doc in snapshot.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All favorites cleared"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error clearing favorites: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  // Format date
  String _formatDate(DateTime date) {
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
  }
}