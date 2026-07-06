import 'package:cloud_firestore/cloud_firestore.dart';


class PlantMasterService {
  PlantMasterService._();

  static final PlantMasterService instance = PlantMasterService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _plants = [];

  /// Load all active plants once
  Future<void> loadPlants() async {
    if (_plants.isNotEmpty) return;

    final snapshot = await _firestore
        .collection("plant_master")
        .where("active", isEqualTo: true)
        .orderBy("name")
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

  /// All Categories
  List<String> get categories {
    final list = _plants
        .map((e) => e["category"].toString())
        .toSet()
        .toList();

    list.sort();

    return list;
  }

  /// Plants of a category
  List<Map<String, dynamic>> plantsByCategory(
      String category) {
    return _plants
        .where((e) => e["category"] == category)
        .toList();
  }

  /// Search by name
  List<Map<String, dynamic>> search(String keyword) {
    final text = keyword.toLowerCase();

    return _plants.where((plant) {
      return plant["name"]
          .toString()
          .toLowerCase()
          .contains(text);
    }).toList();
  }

  /// Refresh cache
  Future<void> refresh() async {
    _plants.clear();
    await loadPlants();
  }
}