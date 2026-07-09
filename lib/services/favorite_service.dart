import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add plant to favorites
  Future<void> addFavorite(String plantId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(plantId)
        .set({
      'plantId': plantId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove plant from favorites
  Future<void> removeFavorite(String plantId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(plantId)
        .delete();
  }

  // Check if plant is in favorites
  Future<bool> isFavorite(String plantId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(plantId)
        .get();

    return doc.exists;
  }

  // Get user's favorite plant IDs
  Stream<List<String>> getFavoriteIds() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.id).toList();
        });
  }

  // Get user's favorite plants (with data)
  Stream<List<Map<String, dynamic>>> getFavorites() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> favorites = [];
          for (var doc in snapshot.docs) {
            final plantDoc = await _firestore
                .collection('plants')
                .doc(doc.id)
                .get();
            if (plantDoc.exists) {
              favorites.add({
                'id': doc.id,
                ...plantDoc.data() as Map<String, dynamic>,
              });
            }
          }
          return favorites;
        });
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String plantId) async {
    final isFav = await isFavorite(plantId);
    if (isFav) {
      await removeFavorite(plantId);
      return false;
    } else {
      await addFavorite(plantId);
      return true;
    }
  }

  // Get favorite count for a plant
  Future<int> getFavoriteCount(String plantId) async {
    final snapshot = await _firestore
        .collectionGroup('favorites')
        .where('plantId', isEqualTo: plantId)
        .get();
    return snapshot.docs.length;
  }
}