import 'package:flutter/material.dart';

import '../add_plant/add_plant_screen.dart';
import 'all_plants_screen.dart';
import '../favorites/favorite_screen.dart';
import '../my_plants/my_plants_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌱 PlantMitra"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Plant"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPlantScreen(),
            ),
          );
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _menuCard(
              context,
              title: "All Plants",
              subtitle: "Browse all available plants",
              icon: Icons.local_florist,
              color: Colors.green,
              isFree: null,
            ),

            const SizedBox(height: 16),

            _menuCard(
              context,
              title: "Free Plants",
              subtitle: "Plants available for free",
              icon: Icons.card_giftcard,
              color: Colors.blue,
              isFree: true,
            ),

            const SizedBox(height: 16),

            _menuCard(
              context,
              title: "Paid Plants",
              subtitle: "Plants available for sale",
              icon: Icons.currency_rupee,
              color: Colors.orange,
              isFree: false,
            ),
          ],
        ),
      ),

      

      bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0,
  selectedItemColor: Colors.green,
  type: BottomNavigationBarType.fixed,

  onTap: (index) {

    switch (index) {

      case 0:
        // Already Home
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FavoriteScreen(),
          ),
        );
        break;

      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chat screen coming soon..."),
          ),
        );
        break;

      case 3:
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const MyPlantsScreen(),
    ),
  );
  break;
    }
  },

  items: const [

    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Home",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.favorite),
      label: "Favorites",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: "Chat",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Profile",
    ),

  ],
),
    );
  }
  

  Widget _menuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool? isFree,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllPlantsScreen(
                isFree: isFree,
                title: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [

              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(.15),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}