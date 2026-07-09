import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/plant_count_service.dart';
import 'package:plantmitra_1/services/plant_master_service.dart';
import 'package:plantmitra_1/screens/home/all_plants_screen.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/favorites/favorite_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_list_screen.dart';
import 'package:plantmitra_1/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlantCountService _countService = PlantCountService();
  final PlantMasterService _masterService = PlantMasterService.instance;
  Map<String, int> _counts = {};
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load master plants first
      await _masterService.loadPlants();
      print("Master plants loaded: ${_masterService.plants.length}");
      
      // Load counts
      final counts = await _countService.getAllCounts();
      setState(() {
        _counts = counts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    try {
      final counts = await _countService.getAllCounts();
      setState(() {
        _counts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _counts['total'] ?? 0;
    final freeCount = _counts['free'] ?? 0;
    final forSaleCount = _counts['forSale'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'PlantMitra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: All Plants
                    _buildSectionCard(
                      title: 'All Plants ($totalCount)',
                      subtitle: 'Browse all listings',
                      icon: Icons.local_florist,
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllPlantsScreen(
                              title: 'All Plants',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Free Plants
                    _buildSectionCard(
                      title: 'Free Plants ($freeCount)',
                      subtitle: 'Browse all listings',
                      icon: Icons.volunteer_activism,
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllPlantsScreen(
                              title: 'Free Plants',
                              isFree: true,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Plants for Sale
                    _buildSectionCard(
                      title: 'Plants for sale ($forSaleCount)',
                      subtitle: 'Browse all listings',
                      icon: Icons.attach_money,
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllPlantsScreen(
                              title: 'Plants for Sale',
                              isFree: false,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // Quick Stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total',
                            totalCount.toString(),
                            Icons.local_florist,
                            Colors.green,
                          ),
                          _buildStatItem(
                            'Free',
                            freeCount.toString(),
                            Icons.volunteer_activism,
                            Colors.green,
                          ),
                          _buildStatItem(
                            'For Sale',
                            forSaleCount.toString(),
                            Icons.attach_money,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Add Plant Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPlantScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Plant'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        switch (index) {
          case 0:
            // Already on Home
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatListScreen(),
              ),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}