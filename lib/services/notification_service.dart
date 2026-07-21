// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:plantmitra_1/utils/logger.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = true,
    this.chatMessages = true,
    this.listingActivity = true,
    this.nearbyPlants = false,
    this.marketing = false,
  });

  final bool enabled;
  final bool chatMessages;
  final bool listingActivity;
  final bool nearbyPlants;
  final bool marketing;

  NotificationPreferences copyWith({
    bool? enabled,
    bool? chatMessages,
    bool? listingActivity,
    bool? nearbyPlants,
    bool? marketing,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      chatMessages: chatMessages ?? this.chatMessages,
      listingActivity: listingActivity ?? this.listingActivity,
      nearbyPlants: nearbyPlants ?? this.nearbyPlants,
      marketing: marketing ?? this.marketing,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'chatMessages': chatMessages,
        'listingActivity': listingActivity,
        'nearbyPlants': nearbyPlants,
        'marketing': marketing,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      enabled: map['enabled'] is bool ? map['enabled'] as bool : true,
      chatMessages:
          map['chatMessages'] is bool ? map['chatMessages'] as bool : true,
      listingActivity: map['listingActivity'] is bool
          ? map['listingActivity'] as bool
          : true,
      nearbyPlants:
          map['nearbyPlants'] is bool ? map['nearbyPlants'] as bool : false,
      marketing: map['marketing'] is bool ? map['marketing'] as bool : false,
    );
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<NotificationPreferences> loadPreferences() async {
    final uid = _uid;
    if (uid == null) return const NotificationPreferences();
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final raw = snapshot.data()?['notificationPreferences'];
    return NotificationPreferences.fromMap(
      raw is Map ? Map<String, dynamic>.from(raw) : null,
    );
  }

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<AuthorizationStatus> permissionStatus() async {
    return (await _messaging.getNotificationSettings()).authorizationStatus;
  }

  Future<void> initializeForCurrentUser() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final preferences = await loadPreferences();
      await _messaging.setAutoInitEnabled(preferences.enabled);
      if (preferences.enabled) {
        await requestPermission();
        await _saveToken();
      }
      await _syncTopics(preferences);
      _messaging.onTokenRefresh.listen((token) async {
        await _storeToken(uid, token);
      });
    } catch (error) {
      Logger.warning('Notification initialization warning: $error');
    }
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    final uid = _uid;
    if (uid == null) throw StateError('User must be signed in.');
    await _firestore.collection('users').doc(uid).set({
      'notificationPreferences': preferences.toMap(),
      'notificationPreferencesUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _messaging.setAutoInitEnabled(preferences.enabled);
    if (preferences.enabled) {
      await requestPermission();
      await _saveToken();
    }
    await _syncTopics(preferences);
  }

  Future<void> _saveToken() async {
    final uid = _uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) await _storeToken(uid, token);
  }

  Future<void> _storeToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _syncTopics(NotificationPreferences preferences) async {
    await _setTopic('jarvis_green_general', preferences.enabled);
    await _setTopic(
      'jarvis_green_nearby_plants',
      preferences.enabled && preferences.nearbyPlants,
    );
    await _setTopic(
      'jarvis_green_marketing',
      preferences.enabled && preferences.marketing,
    );
  }

  Future<void> _setTopic(String topic, bool subscribe) async {
    try {
      if (subscribe) {
        await _messaging.subscribeToTopic(topic);
      } else {
        await _messaging.unsubscribeFromTopic(topic);
      }
    } catch (error) {
      Logger.warning('FCM topic $topic update warning: $error');
    }
  }
}
