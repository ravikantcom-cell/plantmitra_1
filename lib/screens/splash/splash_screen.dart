import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Splash screen duration
  static const Duration splashDuration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    Logger.debug('🚀 SplashScreen started');
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    Logger.debug('Checking login status...');

    // Show splash for a short time
    await Future.delayed(splashDuration);

    final user = FirebaseAuth.instance.currentUser;

    Logger.debug('User UID : ${user?.uid}');
    Logger.debug('User Name: ${user?.displayName}');
    Logger.debug('User Email: ${user?.email}');

    if (!mounted) return;

    if (user != null) {
      Logger.info('User already logged in');

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Logger.info('No logged in user');

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    Logger.debug('Building SplashScreen');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade500,
              Colors.green.shade300,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    "assets/logo/jarvis_green_logo_transparent.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Jarvis Green",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Your Plant Companion",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 50),

              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}