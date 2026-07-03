import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../../services/auth_service.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_florist,
                size: 120,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              const Text(
                "PlantMitra",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Buy • Sell • Gift Plants & Cuttings",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
  print("BUTTON CLICKED");

  try {
    final user = await AuthService().signInWithGoogle();

    print("Returned User = $user");

    if (user != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    }
  } catch (e) {
    print("LOGIN ERROR = $e");
  }
},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}