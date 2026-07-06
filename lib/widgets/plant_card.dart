import 'package:flutter/material.dart';
import '../services/favorite_service.dart';

class PlantCard extends StatelessWidget {
  final String plantId;
  final Map<String, dynamic> plant;
  final VoidCallback onTap;

  PlantCard({
    super.key,
    required this.plantId,
    required this.plant,
    required this.onTap,
  });

  final FavoriteService favoriteService = FavoriteService();

  @override
  Widget build(BuildContext context) {
    final String name = plant["name"] ?? "Unknown Plant";
    final String location = plant["location"] ?? "";
    final String imageUrl = plant["imageUrl"] ?? "";
    final bool isFree = plant["isFree"] ?? true;
    final int price = (plant["price"] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.green.shade100,
                          child: const Icon(
                            Icons.eco,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.green.shade100,
                        child: const Icon(
                          Icons.eco,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(location),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isFree ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isFree ? "FREE" : "₹ $price",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              StreamBuilder<bool>(
                stream: favoriteService.isFavorite(plantId),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;

                  return IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      await favoriteService.toggleFavorite(plantId);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}