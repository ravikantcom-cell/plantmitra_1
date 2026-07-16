import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:plantmitra_1/screens/auth/login_screen.dart';
import 'package:plantmitra_1/screens/home/home_screen.dart';
import 'package:plantmitra_1/screens/splash/splash_screen.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/favorites/favorite_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_list_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_screen.dart';
import 'package:plantmitra_1/screens/detail/plant_detail_screen.dart';
import 'package:plantmitra_1/screens/profile/profile_screen.dart';
import 'package:plantmitra_1/widgets/session_wrapper.dart';
import 'package:plantmitra_1/widgets/session_listener.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 Main: Starting app...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const PlantMitraApp());
}

class PlantMitraApp extends StatelessWidget {
  const PlantMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PlantMitra",
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),
      ),
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