import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plantmitra_1/services/plant_master_service.dart';

class PlantCountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlantMasterService _masterService = PlantMasterService.instance;

  // Get total plant count
  Future<int> getTotalPlantCount() async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .count()
          .get();
      return snapshot.count ?? 0; // Fix: Handle null with ?? 0
    } catch (e) {
      return 0;
    }
  }

  // Get free plants count
  Future<int> getFreePlantsCount() async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .where('isFree', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0; // Fix: Handle null with ?? 0
    } catch (e) {
      return 0;
    }
  }

  // Get plants for sale count (not free)
  Future<int> getForSalePlantsCount() async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .where('isFree', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0; // Fix: Handle null with ?? 0
    } catch (e) {
      return 0;
    }
  }

  // Get plants by item type
  Future<int> getPlantCountByType(String itemType) async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .where('itemType', isEqualTo: itemType)
          .count()
          .get();
      return snapshot.count ?? 0; // Fix: Handle null with ?? 0
    } catch (e) {
      return 0;
    }
  }

  // Get all counts in one go (more efficient)
  Future<Map<String, int>> getAllCounts() async {
    try {
      // Get all available plants
      final allPlants = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .get();

      int total = allPlants.docs.length;
      int free = 0;
      int forSale = 0;
      int plants = 0;
      int seeds = 0;
      int cuttings = 0;
      int saplings = 0;

      for (var doc in allPlants.docs) {
        final data = doc.data();
        final isFree = data['isFree'] ?? false;
        final itemType = data['itemType'] ?? 'Plant';

        // Count free/for sale
        if (isFree) {
          free++;
        } else {
          forSale++;
        }

        // Count by type
        switch (itemType) {
          case 'Plant':
            plants++;
            break;
          case 'Seed':
            seeds++;
            break;
          case 'Cutting':
            cuttings++;
            break;
          case 'Sapling':
            saplings++;
            break;
        }
      }

      return {
        'total': total,
        'free': free,
        'forSale': forSale,
        'plants': plants,
        'seeds': seeds,
        'cuttings': cuttings,
        'saplings': saplings,
      };
    } catch (e) {
      return {
        'total': 0,
        'free': 0,
        'forSale': 0,
        'plants': 0,
        'seeds': 0,
        'cuttings': 0,
        'saplings': 0,
      };
    }
  }

  // Get recent plants (for preview cards)
  Future<List<Map<String, dynamic>>> getRecentPlants({
    bool? isFree,
    int limit = 5,
  }) async {
    try {
      Query query = _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .orderBy('createdAt', descending: true);

      if (isFree != null) {
        query = query.where('isFree', isEqualTo: isFree);
      }

      final snapshot = await query.limit(limit).get();

      // Fix: Properly cast the data to Map<String, dynamic>
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data, // Now data is correctly typed as Map<String, dynamic>
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get plants by master plant ID
  Future<List<Map<String, dynamic>>> getPlantsByMasterId(String masterPlantId) async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .where('masterPlantId', isEqualTo: masterPlantId)
          .get();

      // Fix: Properly cast the data to Map<String, dynamic>
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data, // Now data is correctly typed as Map<String, dynamic>
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get plants by category
  Future<List<Map<String, dynamic>>> getPlantsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get plants by sub category
  Future<List<Map<String, dynamic>>> getPlantsBySubCategory(String subCategory) async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .where('subCategory', isEqualTo: subCategory)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all plants with pagination
  Future<List<Map<String, dynamic>>> getPlants({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get plant by ID
  Future<Map<String, dynamic>?> getPlantById(String plantId) async {
    try {
      final doc = await _firestore.collection('plants').doc(plantId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search plants by name or scientific name
  Future<List<Map<String, dynamic>>> searchPlants(String searchTerm) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation using startsWith
      final term = searchTerm.toLowerCase();
      
      // Search by name (starts with)
      final nameSnapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .orderBy('name')
          .startAt([term])
          .endAt([term + '\uf8ff'])
          .limit(20)
          .get();

      // Search by scientific name (starts with)
      final scientificSnapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .orderBy('scientificName')
          .startAt([term])
          .endAt([term + '\uf8ff'])
          .limit(10)
          .get();

      // Combine results (avoid duplicates)
      final Map<String, Map<String, dynamic>> combined = {};
      
      for (var doc in nameSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        combined[doc.id] = {
          'id': doc.id,
          ...data,
        };
      }
      
      for (var doc in scientificSnapshot.docs) {
        if (!combined.containsKey(doc.id)) {
          final data = doc.data() as Map<String, dynamic>;
          combined[doc.id] = {
            'id': doc.id,
            ...data,
          };
        }
      }

      return combined.values.toList();
    } catch (e) {
      return [];
    }
  }

  // Get count of plants by master plant ID
  Future<int> getCountByMasterPlantId(String masterPlantId) async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('status', isEqualTo: 'Available')
          .where('masterPlantId', isEqualTo: masterPlantId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}