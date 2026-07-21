// lib/screens/splash/splash_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _splashDuration = Duration(milliseconds: 2000);
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    Logger.debug('SplashScreen started');
    _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    try {
      await Future<void>.delayed(_splashDuration);

      if (!mounted || _hasNavigated) return;

      final user = FirebaseAuth.instance.currentUser;
      _hasNavigated = true;

      Logger.debug(
        user == null
            ? 'Splash: opening login screen'
            : 'Splash: opening home screen for ${user.uid}',
      );

      Navigator.of(context).pushReplacementNamed(
        user == null ? '/login' : '/home',
      );
    } catch (error) {
      Logger.error('Splash navigation failed: $error');

      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5FBF5),
              Color(0xFFEAF7EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  tween: Tween<double>(begin: 0.78, end: 1),
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 220,
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD9EEDC),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F18864B),
                          blurRadius: 32,
                          spreadRadius: 3,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/jarvis_green_logo_transparent.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF0F8F1),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFF18864B),
                              size: 76,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Jarvis Green',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF174D2B),
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 11),
                const Text(
                  'Grow  •  Share  •  Connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Your greener journey starts here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF69806E),
                    fontSize: 13,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: const LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Color(0xFFD7E9D9),
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Preparing your garden…',
                  style: TextStyle(
                    color: Color(0xFF607565),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
