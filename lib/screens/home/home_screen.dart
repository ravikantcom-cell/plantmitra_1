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
            // All Section
            ExpansionTile(
              leading: const Icon(Icons.local_florist, color: Colors.green),
              title: const Text(
                "All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                _typeButton(context, "Plants", null, "Plant"),
                _typeButton(context, "Seeds", null, "Seed"),
                _typeButton(context, "Cuttings", null, "Cutting"),
                _typeButton(context, "Saplings", null, "Sapling"),
              ],
            ),

            const SizedBox(height: 12),

            // Free Section
            ExpansionTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.blue),
              title: const Text(
                "Free",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                _typeButton(context, "Plants", true, "Plant"),
                _typeButton(context, "Seeds", true, "Seed"),
                _typeButton(context, "Cuttings", true, "Cutting"),
                _typeButton(context, "Saplings", true, "Sapling"),
              ],
            ),

            const SizedBox(height: 12),

            // Paid Section
            ExpansionTile(
              leading: const Icon(Icons.currency_rupee, color: Colors.orange),
              title: const Text(
                "Paid",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                _typeButton(context, "Plants", false, "Plant"),
                _typeButton(context, "Seeds", false, "Seed"),
                _typeButton(context, "Cuttings", false, "Cutting"),
                _typeButton(context, "Saplings", false, "Sapling"),
              ],
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

  Widget _typeButton(
    BuildContext context,
    String title,
    bool? isFree,
    String itemType,
  ) {
    return ListTile(
      leading: const Icon(
        Icons.arrow_right,
        color: Colors.green,
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllPlantsScreen(
  title:
      "${isFree == null ? "All" : isFree ? "Free" : "Paid"} $title",
  isFree: isFree,
  itemType: itemType,
),
          ),
        );
      },
    );
  }

  // Optional: Keep this method if you plan to use _menuCard later
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