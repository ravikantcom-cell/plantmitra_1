import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadPlantImage(File image) async {
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg";

    final ref = _storage.ref().child("plant_images/$fileName");

    final task = ref.putFile(image);

    final snapshot = await task;

    return snapshot.ref.getDownloadURL();
  }
}