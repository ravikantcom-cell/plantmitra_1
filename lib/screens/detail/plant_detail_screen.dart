import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:plantmitra/services/favorite_service.dart';
import '../chat/chat_screen.dart';
import '../edit_plant/edit_plant_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> plant;

  const PlantDetailScreen({
    super.key,
    required this.documentId,
    required this.plant,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final FavoriteService favoriteService = FavoriteService();
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
    _increaseView();
  }

  // ✅ FIX: Stream ko listen karein
  Future<void> _loadFavoriteState() async {
    try {
      final isFav = await favoriteService.isFavorite(widget.documentId).first;
      if (mounted) {
        setState(() {
          isFavorite = isFav;
        });
      }
    } catch (e) {
      print("Error loading favorite state: $e");
    }
  }

  // ✅ FIX: Views badhayein
  Future<void> _increaseView() async {
    try {
      await FirebaseFirestore.instance
          .collection("plants")
          .doc(widget.documentId)
          .update({
        "views": FieldValue.increment(1),
      });

      if (mounted) {
        setState(() {
          widget.plant["views"] = (widget.plant["views"] ?? 0) + 1;
        });
      }
    } catch (e) {
      print("Error updating views: $e");
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "Please login to favorite");
      return;
    }

    final uid = user.uid;
    final plantRef = FirebaseFirestore.instance.collection("plants").doc(widget.documentId);
    final favRef = FirebaseFirestore.instance.collection("users").doc(uid).collection("favorites").doc(widget.documentId);
    final favDoc = await favRef.get();

    try {
      if (favDoc.exists) {
        // Unfavorite
        await favRef.delete();
        await plantRef.update({"favoriteCount": FieldValue.increment(-1)});
        if (mounted) {
          setState(() {
            isFavorite = false;
            widget.plant["favoriteCount"] = (widget.plant["favoriteCount"] ?? 1) - 1;
          });
          Fluttertoast.showToast(msg: "Removed from favorites", toastLength: Toast.LENGTH_SHORT);
        }
      } else {
        // Favorite
        await favRef.set({"createdAt": FieldValue.serverTimestamp()});
        await plantRef.update({"favoriteCount": FieldValue.increment(1)});
        if (mounted) {
          setState(() {
            isFavorite = true;
            widget.plant["favoriteCount"] = (widget.plant["favoriteCount"] ?? 0) + 1;
          });
          Fluttertoast.showToast(msg: "Added to favorites! ❤️", toastLength: Toast.LENGTH_SHORT);
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: "Failed to update favorite");
      }
    }
  }

  Future<void> deletePlant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Plant"),
        content: const Text("Are you sure you want to delete this plant?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection("plants").doc(widget.documentId).delete();
      if (mounted) {
        Fluttertoast.showToast(msg: "Plant Deleted Successfully", backgroundColor: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && user.uid == widget.plant["ownerId"];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plant["name"] ?? "Plant"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 260,
              color: Colors.green.shade100,
              child: (widget.plant["imageUrl"] ?? "").toString().isNotEmpty
                  ? Image.network(
                      widget.plant["imageUrl"],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.local_florist, size: 120, color: Colors.green),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.local_florist, size: 120, color: Colors.green),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plant["name"] ?? "",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  if ((widget.plant["scientificName"] ?? "").toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        widget.plant["scientificName"],
                        style: TextStyle(fontSize: 17, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.plant["location"] ?? "")),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.category, color: Colors.green),
                      title: Text("Category : ${widget.plant["category"] ?? "-"}"),
                      subtitle: Text("Sub Category : ${widget.plant["subCategory"] ?? "-"}"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(widget.plant["description"] ?? "No description"),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      const Text("Price : ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        widget.plant["isFree"] == true ? "FREE 🌱" : "₹ ${widget.plant["price"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: widget.plant["isFree"] == true ? Colors.green : Colors.orange,
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 25),

                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        backgroundImage: (widget.plant["ownerPhoto"] ?? "").toString().isNotEmpty
                            ? NetworkImage(widget.plant["ownerPhoto"])
                            : null,
                        child: (widget.plant["ownerPhoto"] ?? "").toString().isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(widget.plant["ownerName"] ?? ""),
                      subtitle: Text(widget.plant["ownerEmail"] ?? ""),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.favorite, color: Colors.red),
                          Text("${widget.plant["favoriteCount"] ?? 0}"),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.chat, color: Colors.blue),
                          Text("${widget.plant["chatCount"] ?? 0}"),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.visibility, color: Colors.green),
                          Text("${widget.plant["views"] ?? 0}"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        icon: const Icon(Icons.chat),
                        label: const Text("Chat with Owner"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                plantId: widget.documentId,
                                receiverId: widget.plant["ownerId"],
                                receiverName: widget.plant["ownerName"] ?? "",
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 25),

                  if (isOwner)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditPlantScreen(
                                    documentId: widget.documentId,
                                    plant: widget.plant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            icon: const Icon(Icons.delete),
                            label: const Text("Delete"),
                            onPressed: deletePlant,
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