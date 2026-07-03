import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Add / Remove favorite
  Future<void> toggleFavorite(String plantId) async {
    final ref = _firestore
        .collection("users")
        .doc(_uid)
        .collection("favorites")
        .doc(plantId);

    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        "plantId": plantId,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  /// Check if favorite
  Stream<bool> isFavorite(String plantId) {
    return _firestore
        .collection("users")
        .doc(_uid)
        .collection("favorites")
        .doc(plantId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Favorite list
  Stream<QuerySnapshot> favoritePlants() {
    return _firestore
        .collection("users")
        .doc(_uid)
        .collection("favorites")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }
}