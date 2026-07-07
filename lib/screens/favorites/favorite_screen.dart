import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get uid => auth.currentUser!.uid;

  Future<bool> isFavorite(String plantId) async {
    final doc = await firestore
        .collection("users")
        .doc(uid)
        .collection("favorites")
        .doc(plantId)
        .get();

    return doc.exists;
  }

  Future<void> toggleFavorite(String plantId) async {
    final favRef = firestore
        .collection("users")
        .doc(uid)
        .collection("favorites")
        .doc(plantId);

    final plantRef =
        firestore.collection("plants").doc(plantId);

    final favDoc = await favRef.get();

    if (favDoc.exists) {
      await favRef.delete();

      await plantRef.update({
        "favoriteCount": FieldValue.increment(-1),
      });
    } else {
      await favRef.set({
        "createdAt": FieldValue.serverTimestamp(),
      });

      await plantRef.update({
        "favoriteCount": FieldValue.increment(1),
      });
    }
  }
}