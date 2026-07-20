import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  /// Firebase instance
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Public getter
  static FirebaseFirestore get db => _db;

  /// Collections
  static CollectionReference<Map<String, dynamic>> get users =>
      _db.collection("users");

  static CollectionReference<Map<String, dynamic>> get plants =>
      _db.collection("plants");

  static CollectionReference<Map<String, dynamic>> get masterPlants =>
    _db.collection("plant_master");

  static CollectionReference<Map<String, dynamic>> get chats =>
      _db.collection("chats");

  /// ===========================
  /// USER METHODS
  /// ===========================

  static Future<void> saveUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await users.doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
      String uid) async {
    return users.doc(uid).get();
  }

  /// ===========================
  /// PLANT METHODS
  /// ===========================

  static Future<DocumentReference<Map<String, dynamic>>> addPlant(
    Map<String, dynamic> data,
  ) async {
    return plants.add(data);
  }

  static Future<void> updatePlant(
    String plantId,
    Map<String, dynamic> data,
  ) async {
    await plants.doc(plantId).update(data);
  }

  static Future<void> deletePlant(String plantId) async {
    await plants.doc(plantId).delete();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getPlant(
      String plantId) async {
    return plants.doc(plantId).get();
  }

  /// ===========================
  /// CHAT METHODS
  /// ===========================

  static CollectionReference<Map<String, dynamic>> chatMessages(
      String chatId) {
    return chats.doc(chatId).collection("messages");
  }
}