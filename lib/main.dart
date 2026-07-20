// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:plantmitra_1/screens/auth/login_screen.dart';
import 'package:plantmitra_1/screens/home/home_screen.dart';
import 'package:plantmitra_1/screens/splash/splash_screen.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/favorites/favorite_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_list_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_screen.dart';
import 'package:plantmitra_1/screens/detail/plant_detail_screen.dart';
import 'package:plantmitra_1/screens/profile/profile_screen.dart';
import 'package:plantmitra_1/utils/logger.dart';
import 'package:plantmitra_1/theme/app_theme.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.info('🚀 Jarvis Green: Starting app...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.info('✅ Firebase initialized successfully!');
    
    await _setupFirebaseMessaging();
  } catch (e) {
    Logger.error('❌ Firebase initialization error: $e');
  }

  runApp(const JarvisGreenApp());
}

Future<void> _setupFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    Logger.info('Notification permission: ${settings.authorizationStatus}');
  } catch (e) {
    Logger.warning('Could not setup Firebase Messaging: $e');
  }
}

class JarvisGreenApp extends StatelessWidget {
  const JarvisGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Jarvis Green",
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/add_plant': (context) => const AddPlantScreen(),
        '/favorites': (context) => const FavoriteScreen(),
        '/chats': (context) => const ChatListScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              senderId: args['senderId'],
              receiverId: args['receiverId'],
              receiverName: args['receiverName'],
            ),
          );
        }
        if (settings.name == '/plant_detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PlantDetailScreen(
              documentId: args['documentId'],
              plant: args['plant'],
            ),
          );
        }
        return null;
      },
    );
  }
}
