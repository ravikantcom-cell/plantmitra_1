import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantmitra/services/favorite_service.dart';
import 'package:plantmitra/screens/detail/plant_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  List<dynamic> _favoritePlants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final favorites = await _favoriteService.getFavorites(userId);
        setState(() {
          _favoritePlants = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading favorites: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("❤️ Favorites"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoritePlants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No favorite plants yet",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _favoritePlants.length,
                  itemBuilder: (context, index) {
                    final plant = _favoritePlants[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.local_florist, color: Colors.green),
                      ),
                      title: Text(
                        plant['name'] ?? 'Unknown Plant',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(plant['location'] ?? 'Location not available'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plant['price']?.toString() ?? 'FREE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.favorite, color: Colors.red),
                            onPressed: () => _removeFavorite(plant),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlantDetailScreen(
                              plantId: plant['id'],
                              plantData: plant,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadFavorites,
        child: Icon(Icons.refresh),
      ),
    );
  }

  Future<void> _removeFavorite(dynamic plant) async {
    try {
      await _favoriteService.removeFavorite(
        FirebaseAuth.instance.currentUser!.uid,
        plant['id'],
      );
      _loadFavorites();
    } catch (e) {
      print("Error removing favorite: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove favorite")),
      );
    }
  }
}