import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/favorite_service.dart';
import 'favorite_service.dart';
import 'package:plantmitra/services/favorite_service.dart';

class FavoriteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> toggleFavorite(String plantId) async {
    final ref = _db
        .collection("users")
        .doc(uid)
        .collection("favorites")
        .doc(plantId);

    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isFavorite(String plantId) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("favorites")
        .doc(plantId)
        .snapshots()
        .map((event) => event.exists);
  }
}