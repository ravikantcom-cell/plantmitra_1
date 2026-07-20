// lib/screens/home/all_plants_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/plant_master_service.dart';
import 'package:plantmitra_1/utils/logger.dart';
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

class _AllPlantsScreenState extends State<AllPlantsScreen> {
  final PlantMasterService _masterService = PlantMasterService.instance;
  
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
    
    // Set selected item type from widget
    if (widget.itemType != null) {
      selectedItemType = widget.itemType!;
    }
    
    // Load master plants for reference
    _masterService.loadPlants();
  }

  // Get master plant name from masterPlantId
  String _getMasterPlantName(String? masterPlantId) {
    if (masterPlantId == null || masterPlantId.isEmpty) return '';
    final masterPlant = _masterService.getPlant(masterPlantId);
    return masterPlant?['name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection("plants")
        .where("status", isEqualTo: "Available");

    // Filter by free status
    if (widget.isFree != null) {
      query = query.where(
        "isFree",
        isEqualTo: widget.isFree,
      );
    }

    // Filter by item type
    if (widget.itemType != null && widget.itemType != "All") {
      query = query.where(
        "itemType",
        isEqualTo: widget.itemType,
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
        elevation: 0,
        actions: [
          // Clear filters button
          if (selectedCategory != "All" || searchText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  selectedCategory = "All";
                  searchText = "";
                  selectedItemType = widget.itemType ?? "All";
                });
              },
            ),
        ],
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
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchText = "";
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // CATEGORY BUTTONS - Horizontal Scroll
          SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = selectedCategory == category;
                  return FilterChip(
                    avatar: Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: selected ? Colors.white : Colors.green,
                    ),
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.white,
                    elevation: selected ? 4 : 1,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: selected ? Colors.green : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ITEM TYPE BUTTONS - Only show if not passed from parent
          if (widget.itemType == null)
            SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = itemTypes[index];
                    final selected = selectedItemType == item;
                    return FilterChip(
                      avatar: Icon(
                        _getItemIcon(item),
                        size: 16,
                        color: selected ? Colors.white : Colors.blue,
                      ),
                      label: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.white,
                      elevation: selected ? 4 : 1,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(
                          color: selected ? Colors.blue : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedItemType = item;
                        });
                      },
                    );
                  },
                ),
              ),
            ),

          if (widget.itemType == null) const SizedBox(height: 12),

          // PLANTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.green,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading plants...",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  Logger.error("Error loading plants: ${snapshot.error}");
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
                          "Error loading plants",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
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

                List<QueryDocumentSnapshot> plants = snapshot.data?.docs ?? [];

                // SEARCH FILTER (Client-side)
                if (searchText.isNotEmpty) {
                  plants = plants.where((doc) {
                    final plant = doc.data() as Map<String, dynamic>;
                    final name = (plant["name"] ?? "").toString().toLowerCase();
                    final scientific = (plant["scientificName"] ?? "").toString().toLowerCase();
                    final masterPlantId = (plant["masterPlantId"] ?? "").toString().toLowerCase();
                    final masterName = _getMasterPlantName(masterPlantId).toLowerCase();
                    
                    return name.contains(searchText) ||
                        scientific.contains(searchText) ||
                        masterName.contains(searchText);
                  }).toList();
                }

                // CATEGORY FILTER (Client-side)
                if (selectedCategory != "All") {
                  plants = plants.where((doc) {
                    final plant = doc.data() as Map<String, dynamic>;
                    final category = (plant["category"] ?? "").toString().toLowerCase();
                    final subCategory = (plant["subCategory"] ?? "").toString().toLowerCase();
                    final filter = selectedCategory.toLowerCase();
                    return category.contains(filter) || subCategory.contains(filter);
                  }).toList();
                }

                // ITEM TYPE FILTER (Client-side) - Only if not passed from parent
                if (widget.itemType == null && selectedItemType != "All") {
                  plants = plants.where((doc) {
                    final plant = doc.data() as Map<String, dynamic>;
                    final itemType = (plant["itemType"] ?? "Plant").toString().toLowerCase();
                    return itemType == selectedItemType.toLowerCase();
                  }).toList();
                }

                // EMPTY STATE
                if (plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_florist,
                          size: 80,
                          color: Colors.green.shade200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No Plants Found",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchText.isNotEmpty || selectedCategory != "All"
                              ? "Try adjusting your search or filters"
                              : "Check back later for new plants",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (searchText.isNotEmpty || selectedCategory != "All")
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  searchText = "";
                                  selectedCategory = "All";
                                  selectedItemType = widget.itemType ?? "All";
                                });
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text("Clear Filters"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // PLANT LIST
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plantDoc = plants[index];
                    final plant = plantDoc.data() as Map<String, dynamic>;

                    // Get master plant name
                    final masterPlantId = plant["masterPlantId"] ?? "";
                    final masterPlantName = _getMasterPlantName(masterPlantId);

                    return Card(
                      elevation: 3,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // IMAGE
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  plant["imageUrl"] ?? "",
                                  width: 95,
                                  height: 95,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 95,
                                      height: 95,
                                      color: Colors.green.shade50,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.green,
                                        ),
                                      ),
                                    );
                                  },
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

                              // PLANT INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      plant["name"] ?? "Unknown Plant",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    // Master Plant Name (if available)
                                    if (masterPlantName.isNotEmpty)
                                      Text(
                                        masterPlantName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    const SizedBox(height: 4),

                                    // Scientific Name
                                    if ((plant["scientificName"] ?? "").toString().isNotEmpty)
                                      Text(
                                        plant["scientificName"],
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                    const SizedBox(height: 6),

                                    // Tags
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        // Category Badge
                                        if ((plant["category"] ?? "").toString().isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              plant["category"] ?? "",
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        
                                        // Sub Category Badge
                                        if ((plant["subCategory"] ?? "").toString().isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              plant["subCategory"] ?? "",
                                              style: TextStyle(
                                                color: Colors.purple.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        
                                        // Item Type Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            plant["itemType"] ?? "Plant",
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

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
                                            plant["location"] ?? "Location not specified",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Price and Stats
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
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),

                                        const Spacer(),

                                        // Favorite count
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              "${plant["favoriteCount"] ?? 0}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(width: 12),

                                        // Views count
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.visibility,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              "${plant["views"] ?? 0}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
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