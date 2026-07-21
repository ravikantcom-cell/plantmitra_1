// lib/main.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/auth/login_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_list_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_screen.dart';
import 'package:plantmitra_1/screens/detail/plant_detail_screen.dart';
import 'package:plantmitra_1/screens/favorites/favorite_screen.dart';
import 'package:plantmitra_1/screens/home/home_screen.dart';
import 'package:plantmitra_1/screens/profile/profile_screen.dart';
import 'package:plantmitra_1/screens/splash/splash_screen.dart';
import 'package:plantmitra_1/services/notification_service.dart';
import 'package:plantmitra_1/theme/app_theme.dart';
import 'package:plantmitra_1/utils/logger.dart';

import 'firebase_options.dart';

StreamSubscription<User?>? _authSubscription;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.info('Jarvis Green: Starting app...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.info('Firebase initialized successfully.');

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        if (user != null) {
          await NotificationService.instance.initializeForCurrentUser();
        }
      },
      onError: (Object error) {
        Logger.warning('Authentication listener warning: $error');
      },
    );
  } catch (error) {
    Logger.error('Firebase initialization error: $error');
  }

  runApp(const JarvisGreenApp());
}

class JarvisGreenApp extends StatelessWidget {
  const JarvisGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jarvis Green',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: <String, WidgetBuilder>{
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/add_plant': (_) => const AddPlantScreen(),
        '/favorites': (_) => const FavoriteScreen(),
        '/chats': (_) => const ChatListScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        final rawArguments = settings.arguments;
        final arguments = rawArguments is Map
            ? Map<String, dynamic>.from(rawArguments)
            : <String, dynamic>{};

        if (settings.name == '/chat') {
          return MaterialPageRoute<void>(
            builder: (_) => ChatScreen(
              senderId: arguments['senderId']?.toString() ?? '',
              receiverId: arguments['receiverId']?.toString() ?? '',
              receiverName:
                  arguments['receiverName']?.toString() ?? 'Plant Lover',
              receiverImage: arguments['receiverImage']?.toString(),
              chatId: arguments['chatId']?.toString(),
              plantId: arguments['plantId']?.toString(),
              plantName: arguments['plantName']?.toString(),
              plantImage: arguments['plantImage']?.toString(),
            ),
          );
        }

        if (settings.name == '/plant_detail') {
          final plant = arguments['plant'];
          return MaterialPageRoute<void>(
            builder: (_) => PlantDetailScreen(
              documentId: arguments['documentId']?.toString() ?? '',
              plant: plant is Map
                  ? Map<String, dynamic>.from(plant)
                  : <String, dynamic>{},
            ),
          );
        }

        return null;
      },
    );
  }
}
