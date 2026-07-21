// lib/services/public_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantmitra_1/utils/logger.dart';

class PublicProfileService {
  PublicProfileService._();

  static final PublicProfileService instance = PublicProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, String> _nameCache = <String, String>{};

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('public_profiles');

  Future<void> ensureCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final emailName = user.email?.split('@').first.trim() ?? '';
    final displayName = (user.displayName ?? '').trim().isNotEmpty
        ? user.displayName!.trim()
        : (emailName.isNotEmpty ? emailName : 'Plant Lover');

    try {
      await _profiles.doc(user.uid).set(
        <String, dynamic>{
          'uid': user.uid,
          'displayName': displayName,
          'photoURL': user.photoURL ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _nameCache[user.uid] = displayName;
    } catch (error) {
      Logger.error('Could not update public profile: $error');
    }
  }

  Future<String> getDisplayName(
    String userId, {
    String fallback = 'Plant Lover',
  }) async {
    final cached = _nameCache[userId];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final snapshot = await _profiles.doc(userId).get();
      final name = (snapshot.data()?['displayName'] as String? ?? '').trim();
      if (name.isNotEmpty) {
        _nameCache[userId] = name;
        return name;
      }
    } catch (error) {
      Logger.error('Could not load public display name: $error');
    }

    return fallback.trim().isNotEmpty ? fallback.trim() : 'Plant Lover';
  }

  Future<String?> getPhotoUrl(String userId) async {
    try {
      final snapshot = await _profiles.doc(userId).get();
      final photoUrl = (snapshot.data()?['photoURL'] as String? ?? '').trim();
      return photoUrl.isEmpty ? null : photoUrl;
    } catch (error) {
      Logger.error('Could not load public profile photo: $error');
      return null;
    }
  }
}
