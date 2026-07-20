// lib/widgets/plant_card.dart

import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/favorite_service.dart';
import 'package:plantmitra_1/theme/app_colors.dart';
import 'package:plantmitra_1/theme/app_text_styles.dart';
import 'package:plantmitra_1/utils/logger.dart';

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

  Widget _placeholderImage() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.eco,
        color: AppColors.primary,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = plant["name"] ?? "Unknown Plant";
    final String location = plant["location"] ?? "";
    final String imageUrl = plant["imageUrl"] ?? "";
    final bool isFree = plant["isFree"] ?? true;

    final int price = plant["price"] is int
        ? plant["price"]
        : int.tryParse("${plant["price"]}") ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.subHeading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      location,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isFree
                            ? AppColors.success
                            : AppColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFree ? "FREE" : "₹ $price",
                        style: AppTextStyles.button.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              FutureBuilder<bool>(
                future: favoriteService.isFavorite(plantId),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  return IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : AppColors.icon,
                    ),
                    onPressed: () async {
                      try {
                        await favoriteService.toggleFavorite(
                          plantId,
                        );
                      } catch (e) {
                        Logger.error("Favorite Error : $e");

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text(
                                "Failed to update favorite",
                              ),
                            ),
                          );
                        }
                      }
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