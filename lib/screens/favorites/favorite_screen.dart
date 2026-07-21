// lib/screens/favorites/favorite_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/screens/detail/plant_detail_screen.dart';
import 'package:plantmitra_1/utils/logger.dart';

enum _FavoriteFilter { all, free, forSale }

const Color _darkGreen = Color(0xFF174D2B);
const Color _green = Color(0xFF2E7D32);
const Color _secondaryText = Color(0xFF69806E);

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  _FavoriteFilter _filter = _FavoriteFilter.all;
  String _query = '';
  String? _removingPlantId;
  bool _isClearing = false;
  String _loadedIdsKey = '';
  Future<List<_FavoritePlant>>? _plantsFuture;

  String? get _userId => _auth.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _favoritesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  Future<List<_FavoritePlant>> _loadPlants(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> favorites,
  ) async {
    return Future.wait(favorites.map((favorite) async {
      try {
        final plant = await _firestore.collection('plants').doc(favorite.id).get();
        final addedAt = favorite.data()['addedAt'];
        return _FavoritePlant(
          id: favorite.id,
          plant: plant.data(),
          addedAt: addedAt is Timestamp ? addedAt.toDate() : null,
        );
      } catch (error) {
        Logger.warning('Favorite plant ${favorite.id} could not load: $error');
        return _FavoritePlant(id: favorite.id, plant: null, addedAt: null);
      }
    }));
  }

  List<_FavoritePlant> _visiblePlants(List<_FavoritePlant> plants) {
    return plants.where((entry) {
      final plant = entry.plant;
      if (plant == null) return _query.isEmpty && _filter == _FavoriteFilter.all;
      final isFree = plant['isFree'] == true;
      if (_filter == _FavoriteFilter.free && !isFree) return false;
      if (_filter == _FavoriteFilter.forSale && isFree) return false;
      if (_query.isEmpty) return true;
      final searchable = [
        plant['name'],
        plant['scientificName'],
        plant['category'],
        plant['location'],
      ].where((value) => value != null).join(' ').toLowerCase();
      return searchable.contains(_query);
    }).toList();
  }

  Future<void> _openDetails(_FavoritePlant entry) async {
    if (entry.plant == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantDetailScreen(
          documentId: entry.id,
          plant: Map<String, dynamic>.from(entry.plant!),
        ),
      ),
    );
  }

  Future<void> _removeFavorite(String plantId) async {
    final userId = _userId;
    if (userId == null || _removingPlantId != null || _isClearing) return;
    setState(() => _removingPlantId = plantId);
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(plantId)
          .delete();
      if (mounted) _showMessage('Removed from favorites.');
    } catch (error) {
      Logger.error('Removing favorite failed: $error');
      if (mounted) {
        _showMessage('Could not remove this favorite.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _removingPlantId = null);
    }
  }

  Future<void> _confirmClearAll() async {
    if (_isClearing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.heart_broken_outlined, color: Colors.red),
        title: const Text('Clear all favorites?'),
        content: const Text('Every saved plant will be removed from your favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _clearAll();
  }

  Future<void> _clearAll() async {
    final userId = _userId;
    if (userId == null) return;
    setState(() => _isClearing = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
      if (mounted) _showMessage('All favorites cleared.');
    } catch (error) {
      Logger.error('Clearing favorites failed: $error');
      if (mounted) _showMessage('Could not clear favorites.', isError: true);
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : _darkGreen,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
      ),
      body: userId == null
          ? const _SignedOutView()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _favoritesStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const _LoadingView(label: 'Loading favorites…');
                }
                if (snapshot.hasError) {
                  Logger.error('Favorites stream error: ${snapshot.error}');
                  return const _ErrorView();
                }

                final favorites = snapshot.data?.docs ?? [];
                if (favorites.isEmpty) return const _EmptyFavoritesView();

                final idsKey = favorites.map((doc) => doc.id).join('|');
                if (_plantsFuture == null || idsKey != _loadedIdsKey) {
                  _loadedIdsKey = idsKey;
                  _plantsFuture = _loadPlants(favorites);
                }

                return FutureBuilder<List<_FavoritePlant>>(
                  future: _plantsFuture,
                  builder: (context, plantSnapshot) {
                    if (!plantSnapshot.hasData) {
                      return const _LoadingView(label: 'Loading saved plants…');
                    }
                    final allPlants = plantSnapshot.data!;
                    final visiblePlants = _visiblePlants(allPlants);
                    return CustomScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          sliver: SliverToBoxAdapter(
                            child: _HeaderCard(
                              count: allPlants.length,
                              clearing: _isClearing,
                              onClear: _confirmClearAll,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          sliver: SliverToBoxAdapter(child: _buildSearch()),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                          sliver: SliverToBoxAdapter(child: _buildFilters()),
                        ),
                        if (visiblePlants.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _NoResultsView(),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                            sliver: SliverList.separated(
                              itemCount: visiblePlants.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final entry = visiblePlants[index];
                                return _FavoriteCard(
                                  entry: entry,
                                  removing: _removingPlantId == entry.id,
                                  onTap: () => _openDetails(entry),
                                  onRemove: () => _removeFavorite(entry.id),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search saved plants',
        prefixIcon: const Icon(Icons.search_rounded, color: _green),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDE7DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _green, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _FilterChip(
          label: 'All',
          selected: _filter == _FavoriteFilter.all,
          onTap: () => setState(() => _filter = _FavoriteFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Free',
          selected: _filter == _FavoriteFilter.free,
          onTap: () => setState(() => _filter = _FavoriteFilter.free),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'For sale',
          selected: _filter == _FavoriteFilter.forSale,
          onTap: () => setState(() => _filter = _FavoriteFilter.forSale),
        ),
      ],
    );
  }
}

class _FavoritePlant {
  const _FavoritePlant({required this.id, required this.plant, required this.addedAt});
  final String id;
  final Map<String, dynamic>? plant;
  final DateTime? addedAt;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count, required this.clearing, required this.onClear});
  final int count;
  final bool clearing;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF174D2B), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white, size: 34),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saved plants',
                      style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('$count ${count == 1 ? 'favorite' : 'favorites'}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            TextButton(
              onPressed: clearing ? null : onClear,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: clearing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Clear all'),
            ),
          ],
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: const Color(0xFFE5F4E7),
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFFDDE7DE)),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF2E7D32) : const Color(0xFF69806E),
          fontWeight: FontWeight.w700,
        ),
      );
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.entry,
    required this.removing,
    required this.onTap,
    required this.onRemove,
  });
  final _FavoritePlant entry;
  final bool removing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final plant = entry.plant;
    if (plant == null) {
      return _MissingPlantCard(removing: removing, onRemove: onRemove);
    }
    final name = plant['name']?.toString() ?? 'Unknown plant';
    final location = plant['location']?.toString() ?? 'Location not specified';
    final imageUrl = plant['imageUrl']?.toString() ?? '';
    final isFree = plant['isFree'] == true;
    final price = plant['price'] ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: removing ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E9E1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: imageUrl.isEmpty
                      ? const _ImageFallback()
                      : Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ImageFallback()),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _darkGreen, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: _secondaryText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _secondaryText, fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isFree ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(isFree ? 'FREE' : '₹ $price',
                          style: TextStyle(
                              color: isFree ? _green : const Color(0xFFB26A00),
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove favorite',
                onPressed: removing ? null : onRemove,
                icon: removing
                    ? const SizedBox.square(
                        dimension: 21,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _green))
                    : const Icon(Icons.favorite_rounded, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingPlantCard extends StatelessWidget {
  const _MissingPlantCard({required this.removing, required this.onRemove});
  final bool removing;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.red, size: 36),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plant no longer available',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _darkGreen)),
              SizedBox(height: 3),
              Text('Remove this outdated favorite.',
                  style: TextStyle(color: _secondaryText, fontSize: 12)),
            ]),
          ),
          IconButton(
            onPressed: removing ? null : onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ]),
      );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFE7F3E8),
        alignment: Alignment.center,
        child: const Icon(Icons.local_florist_rounded, color: _green, size: 44),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: _green),
          const SizedBox(height: 13),
          Text(label, style: const TextStyle(color: _secondaryText)),
        ]),
      );
}

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite_border_rounded, color: _green, size: 76),
            SizedBox(height: 17),
            Text('No favorites yet',
                style: TextStyle(color: _darkGreen, fontSize: 22, fontWeight: FontWeight.w800)),
            SizedBox(height: 7),
            Text('Tap the heart on a plant to save it here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _secondaryText)),
          ]),
        ),
      );
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('No matching favorites found.',
            style: TextStyle(color: _secondaryText, fontWeight: FontWeight.w600)),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, color: Colors.red, size: 56),
            SizedBox(height: 14),
            Text('Could not load favorites',
                style: TextStyle(color: _darkGreen, fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 7),
            Text('Please check your connection and Firestore permissions.',
                textAlign: TextAlign.center, style: TextStyle(color: _secondaryText)),
          ]),
        ),
      );
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Please sign in to view your favorites.'),
      );
}
