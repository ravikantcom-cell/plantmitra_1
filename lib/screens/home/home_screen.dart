// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/plant_count_service.dart';
import 'package:plantmitra_1/services/plant_master_service.dart';
import 'package:plantmitra_1/services/session_service.dart';
import 'package:plantmitra_1/screens/home/all_plants_screen.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/favorites/favorite_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_list_screen.dart';
import 'package:plantmitra_1/screens/profile/profile_screen.dart';
import 'package:plantmitra_1/widgets/session_listener.dart';
import 'package:plantmitra_1/utils/logger.dart';
import 'package:plantmitra_1/theme/app_colors.dart';
import 'package:plantmitra_1/theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:google_sign_in/google_sign_in.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlantCountService _countService = PlantCountService();
  final PlantMasterService _masterService = PlantMasterService.instance;
  final SessionService _sessionService = SessionService();
  Map<String, int> _counts = {};
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ✅ FIX: Method ab State class ke andar hai
  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: 10),
              Text("Logout"),
            ],
          ),
          content: const Text(
            "Are you sure you want to log out from Jarvis Green?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _masterService.loadPlants();
      Logger.debug("Master plants loaded: ${_masterService.plants.length}");
      
      final counts = await _countService.getAllCounts();
      setState(() {
        _counts = counts;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error("Error loading data: $e");
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
      Logger.error("Error loading counts: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _counts['total'] ?? 0;
    final freeCount = _counts['free'] ?? 0;
    final forSaleCount = _counts['forSale'] ?? 0;

    return SessionListener(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _showLogoutDialog();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Jarvis Green",
              style: AppTextStyles.heading.copyWith(
                color: AppColors.primary,
              ),
            ),
            iconTheme: const IconThemeData(
              color: AppColors.primary,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  _sessionService.resetTimer();
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
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: All Plants
                        _buildSectionCard(
                          title: 'All Plants ($totalCount)',
                          subtitle: 'Browse all listings',
                          icon: Icons.local_florist,
                          iconColor: AppColors.primary,
                          onTap: () {
                            _sessionService.resetTimer();
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
                          iconColor: AppColors.primary,
                          onTap: () {
                            _sessionService.resetTimer();
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
                          iconColor: AppColors.warning,
                          onTap: () {
                            _sessionService.resetTimer();
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
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.border,
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
                                AppColors.primary,
                              ),
                              _buildStatItem(
                                'Free',
                                freeCount.toString(),
                                Icons.volunteer_activism,
                                AppColors.primary,
                              ),
                              _buildStatItem(
                                'For Sale',
                                forSaleCount.toString(),
                                Icons.attach_money,
                                AppColors.warning,
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
              _sessionService.resetTimer();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddPlantScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Plant'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
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
      elevation: 1,
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
                  color: iconColor.withValues(alpha: 0.1),
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
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary, 
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
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      currentIndex: _selectedIndex,
      onTap: (index) {
        _sessionService.resetTimer();
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