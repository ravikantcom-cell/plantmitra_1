import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> toggleFavorite(String plantId) async {
    if (_uid == null) return;

    final doc = _firestore
        .collection("users")
        .doc(_uid)
        .collection("favorites")
        .doc(plantId);

    final snapshot = await doc.get();

    if (snapshot.exists) {
      await doc.delete();
    } else {
      await doc.set({
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isFavorite(String plantId) {
    if (_uid == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection("users")
        .doc(_uid)
        .collection("favorites")
        .doc(plantId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}