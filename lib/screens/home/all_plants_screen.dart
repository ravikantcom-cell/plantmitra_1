import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../detail/plant_detail_screen.dart';

class AllPlantsScreen extends StatefulWidget {
  final bool? isFree;
  final String title;
  final String? itemType;

  const AllPlantsScreen({
    super.key,
    this.isFree,
    required this.title,
    this.itemType,
  });

  @override
  State<AllPlantsScreen> createState() => _AllPlantsScreenState();
}

class _AllPlantsScreenState
    extends State<AllPlantsScreen> {
  String searchText = "";
  String selectedCategory = "All";
  String selectedItemType = "All";
  
  final List<String> itemTypes = [
    "All",
    "Plant",
    "Seed",
    "Cutting",
    "Sapling",
  ];

  final List<String> categories = const [
    "All",
    "Indoor",
    "Outdoor",
    "Flower",
    "Fruit",
    "Vegetable",
    "Medicinal",
    "Succulent",
    "Herb",
    "Tree",
    "Climber",
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Indoor":
        return Icons.weekend;
      case "Outdoor":
        return Icons.wb_sunny;
      case "Flower":
        return Icons.local_florist;
      case "Fruit":
        return Icons.apple;
      case "Vegetable":
        return Icons.eco;
      case "Medicinal":
        return Icons.medication;
      case "Succulent":
        return Icons.spa;
      case "Herb":
        return Icons.grass;
      case "Tree":
        return Icons.park;
      case "Climber":
        return Icons.forest;
      default:
        return Icons.apps;
    }
  }

  IconData _getItemIcon(String item) {
    switch (item) {
      case "Plant":
        return Icons.local_florist;
      case "Seed":
        return Icons.grain;
      case "Cutting":
        return Icons.content_cut;
      case "Sapling":
        return Icons.park;
      default:
        return Icons.apps;
    }
  }

  @override
void initState() {
  super.initState();

  if (widget.itemType != null) {
    selectedItemType = widget.itemType!;
  }
}

  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection("plants")
        .where("status", isEqualTo: "Available");

    if (widget.isFree != null) {
      query = query.where(
        "isFree",
        isEqualTo: widget.isFree,
      );
    }

    query = query.orderBy(
      "createdAt",
      descending: true,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search plants...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // CATEGORY BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final selected = selectedCategory == category;
                return FilterChip(
                  avatar: Icon(
                    _getCategoryIcon(category),
                    size: 18,
                    color: selected ? Colors.white : Colors.green,
                  ),
                  label: Text(category),
                  selected: selected,
                  selectedColor: Colors.green,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // ITEM TYPE BUTTONS
          /// ITEM TYPE BUTTONS
if (widget.itemType == null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: itemTypes.map((item) {
        final selected = selectedItemType == item;

        return FilterChip(
          avatar: Icon(
            _getItemIcon(item),
            size: 18,
            color: selected ? Colors.white : Colors.green,
          ),
          label: Text(item),
          selected: selected,
          selectedColor: Colors.blue,
          onSelected: (_) {
            setState(() {
              selectedItemType = item;
            });
          },
        );
      }).toList(),
    ),
  ),

if (widget.itemType == null)
  const SizedBox(height: 12),

          // PLANTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }

                List<QueryDocumentSnapshot> plants =
                    snapshot.data?.docs ?? [];

                // SEARCH FILTER
                if (searchText.isNotEmpty) {
                  plants = plants.where((doc) {
                    final plant = doc.data() as Map<String, dynamic>;
                    final name = (plant["name"] ?? "").toString().toLowerCase();
                    final scientific = (plant["scientificName"] ?? "").toString().toLowerCase();
                    return name.contains(searchText) || scientific.contains(searchText);
                  }).toList();
                }

                // CATEGORY FILTER
                if (selectedCategory != "All") {
                  plants = plants.where((doc) {
                    final plant = doc.data() as Map<String, dynamic>;
                    final category = (plant["category"] ?? "").toString().toLowerCase();
                    final subCategory = (plant["subCategory"] ?? "").toString().toLowerCase();
                    final filter = selectedCategory.toLowerCase();
                    return category.contains(filter) || subCategory.contains(filter);
                  }).toList();
                }

                // ITEM TYPE FILTER
                if (selectedItemType != "All") {
                  plants = plants.where((doc) {
                    final plant = doc.data() as Map<String, dynamic>;
                    final itemType = (plant["itemType"] ?? "Plant").toString().toLowerCase();
                    return itemType == selectedItemType.toLowerCase();
                  }).toList();
                }

                if (plants.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Plants Found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plantDoc = plants[index];
                    final plant = plantDoc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlantDetailScreen(
                                documentId: plantDoc.id,
                                plant: plant,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // IMAGE
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  plant["imageUrl"] ?? "",
                                  width: 95,
                                  height: 95,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Container(
                                      width: 95,
                                      height: 95,
                                      color: Colors.green.shade100,
                                      child: const Icon(
                                        Icons.local_florist,
                                        color: Colors.green,
                                        size: 42,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plant["name"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    if ((plant["scientificName"] ?? "").toString().isNotEmpty)
                                      Text(
                                        plant["scientificName"],
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),

                                    const SizedBox(height: 6),

                                    Text(
  plant["category"] ?? "",
  style: const TextStyle(
    color: Colors.grey,
  ),
),

const SizedBox(height: 6),

Wrap(
  spacing: 6,
  runSpacing: 6,
  children: [

    // Item Type Badge
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        plant["itemType"] ?? "Plant",
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ),

    // Sub Category Badge
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        plant["subCategory"] ?? "",
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ),
  ],
),

const SizedBox(height: 8),

Row(
  children: [
    Icon(
      Icons.location_on,
      size: 16,
      color: Colors.green,
    ),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        plant["location"] ?? "",
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),

                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (plant["isFree"] ?? false)
                                                ? Colors.green
                                                : Colors.orange,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            (plant["isFree"] ?? false)
                                                ? "FREE"
                                                : "₹ ${plant["price"] ?? 0}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        const Spacer(),

                                        Row(
                                          children: [
                                            const Icon(Icons.favorite, color: Colors.red, size: 18),
                                            const SizedBox(width: 3),
                                            Text("${plant["favoriteCount"] ?? 0}"),
                                          ],
                                        ),

                                        const SizedBox(width: 12),

                                        Row(
                                          children: [
                                            const Icon(Icons.visibility, color: Colors.green, size: 18),
                                            const SizedBox(width: 3),
                                            Text("${plant["views"] ?? 0}"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}