import 'package:cloud_firestore/cloud_firestore.dart';

class PlantMasterService {
  PlantMasterService._();

  static final PlantMasterService instance = PlantMasterService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _plants = [];

  /// Load all active plants once
  Future<void> loadPlants() async {
    if (_plants.isNotEmpty) return;

    try {
      // Simple query without orderBy to avoid index issues
      final snapshot = await _firestore
          .collection("plant_master")
          .get();

      _plants = snapshot.docs.map((e) {
        final data = e.data();

        return {
          "id": e.id,
          "name": data["name"] ?? "",
          "scientificName": data["scientificName"] ?? "",
          "category": data["category"] ?? "",
          "subCategory": data["subCategory"] ?? "",
          "active": data["active"] ?? true,
        };
      }).toList();

      // Filter active plants
      _plants = _plants.where((p) => p["active"] == true).toList();
      
      // Sort by name
      _plants.sort((a, b) => a["name"].toString().compareTo(b["name"].toString()));

      print("✅ Loaded ${_plants.length} plants from master");
    } catch (e) {
      print("❌ Error loading plant master: $e");
      _plants = [];
    }
  }

  /// Returns all plants
  List<Map<String, dynamic>> get plants => _plants;

  /// Returns plant names only
  List<String> get plantNames {
    return _plants
        .map((e) => e["name"].toString())
        .toList();
  }

  /// Find plant by name
  Map<String, dynamic>? getPlant(String name) {
    try {
      return _plants.firstWhere(
        (e) => e["name"] == name,
      );
    } catch (_) {
      return null;
    }
  }

  /// Find plant by ID
  Map<String, dynamic>? getPlantById(String id) {
    try {
      return _plants.firstWhere(
        (e) => e["id"] == id,
      );
    } catch (_) {
      return null;
    }
  }

  /// All Categories
  List<String> get categories {
    final list = _plants
        .map((e) => e["category"].toString())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    list.sort();

    return list;
  }

  /// Plants of a category
  List<Map<String, dynamic>> plantsByCategory(String category) {
    return _plants
        .where((e) => e["category"] == category)
        .toList();
  }

  /// Search by name
  List<Map<String, dynamic>> search(String keyword) {
    final text = keyword.toLowerCase().trim();

    if (text.isEmpty) return [];

    return _plants.where((plant) {
      final name = plant["name"].toString().toLowerCase();
      final scientific = plant["scientificName"].toString().toLowerCase();
      final category = plant["category"].toString().toLowerCase();
      
      return name.contains(text) ||
          scientific.contains(text) ||
          category.contains(text);
    }).toList();
  }

  /// Refresh cache
  Future<void> refresh() async {
    _plants.clear();
    await loadPlants();
  }
}