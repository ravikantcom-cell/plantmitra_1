// lib/screens/my_plants/my_plants_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/detail/plant_detail_screen.dart';
import 'package:plantmitra_1/screens/edit_plant/edit_plant_screen.dart';
import 'package:plantmitra_1/utils/logger.dart';

enum _PlantFilter { all, free, forSale }

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _secondaryText = Color(0xFF69806E);

  final TextEditingController _searchController = TextEditingController();
  _PlantFilter _filter = _PlantFilter.all;
  String _query = '';
  String? _deletingDocumentId;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _plantStream(String uid) {
    // Sorting happens locally so this query does not require a composite
    // Firestore index for ownerId + createdAt.
    return FirebaseFirestore.instance
        .collection('plants')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedDocuments(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final documents = snapshot.docs.toList();
    documents.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];
      final aMilliseconds = aTime is Timestamp ? aTime.millisecondsSinceEpoch : 0;
      final bMilliseconds = bTime is Timestamp ? bTime.millisecondsSinceEpoch : 0;
      return bMilliseconds.compareTo(aMilliseconds);
    });
    return documents;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final plant = document.data();
      final isFree = plant['isFree'] == true;

      if (_filter == _PlantFilter.free && !isFree) return false;
      if (_filter == _PlantFilter.forSale && isFree) return false;

      if (_query.isEmpty) return true;
      final searchableText = <Object?>[
        plant['name'],
        plant['scientificName'],
        plant['location'],
        plant['category'],
        plant['subCategory'],
      ].whereType<Object>().join(' ').toLowerCase();
      return searchableText.contains(_query);
    }).toList();
  }

  Future<void> _openAddPlant() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
  }

  Future<void> _openDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantDetailScreen(
          documentId: document.id,
          plant: Map<String, dynamic>.from(document.data()),
        ),
      ),
    );
  }

  Future<void> _openEdit(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EditPlantScreen(
          documentId: document.id,
          plant: Map<String, dynamic>.from(document.data()),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    if (_deletingDocumentId != null) return;
    final name = document.data()['name']?.toString() ?? 'this plant';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        title: const Text('Delete listing?'),
        content: Text(
          '“$name” will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) await _deletePlant(document.id);
  }

  Future<void> _deletePlant(String documentId) async {
    setState(() => _deletingDocumentId = documentId);
    try {
      final reference = FirebaseFirestore.instance.collection('plants').doc(documentId);
      final snapshot = await reference.get();
      final ownerId = snapshot.data()?['ownerId']?.toString();

      if (_uid == null || ownerId != _uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Only the owner can delete this listing.',
        );
      }

      await reference.delete();
      if (mounted) _showMessage('Plant deleted successfully.');
    } on FirebaseException catch (error) {
      Logger.error('My Plants delete error: ${error.code} - ${error.message}');
      if (mounted) {
        final message = error.code == 'permission-denied'
            ? 'You do not have permission to delete this plant.'
            : 'Could not delete the plant. Please try again.';
        _showMessage(message, isError: true);
      }
    } catch (error) {
      Logger.error('My Plants delete error: $error');
      if (mounted) {
        _showMessage('Could not delete the plant. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _deletingDocumentId = null);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : _darkGreen,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('My Plants'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: uid == null ? null : _openAddPlant,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add plant'),
      ),
      body: uid == null
          ? const _SignedOutView()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _plantStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const _LoadingView();
                }

                if (snapshot.hasError) {
                  Logger.error('My Plants stream error: ${snapshot.error}');
                  return _ErrorView(error: snapshot.error);
                }

                final allDocuments = snapshot.hasData
                    ? _sortedDocuments(snapshot.data!)
                    : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final visibleDocuments = _filteredDocuments(allDocuments);
                final freeCount = allDocuments
                    .where((document) => document.data()['isFree'] == true)
                    .length;
                final forSaleCount = allDocuments.length - freeCount;

                if (allDocuments.isEmpty) {
                  return _EmptyView(onAddPlant: _openAddPlant);
                }

                return CustomScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: _DashboardCard(
                          total: allDocuments.length,
                          free: freeCount,
                          forSale: forSaleCount,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      sliver: SliverToBoxAdapter(child: _buildSearchField()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      sliver: SliverToBoxAdapter(child: _buildFilters()),
                    ),
                    if (visibleDocuments.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoSearchResults(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        sliver: SliverList.separated(
                          itemCount: visibleDocuments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final document = visibleDocuments[index];
                            return _PlantManagementCard(
                              plant: document.data(),
                              isDeleting: _deletingDocumentId == document.id,
                              onTap: () => _openDetails(document),
                              onEdit: () => _openEdit(document),
                              onDelete: () => _confirmDelete(document),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search your plants',
        prefixIcon: const Icon(Icons.search_rounded, color: _green),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDE7DE)),
        ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _filter == _PlantFilter.all,
            onSelected: () => setState(() => _filter = _PlantFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Free',
            selected: _filter == _PlantFilter.free,
            onSelected: () => setState(() => _filter = _PlantFilter.free),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'For sale',
            selected: _filter == _PlantFilter.forSale,
            onSelected: () => setState(() => _filter = _PlantFilter.forSale),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.total, required this.free, required this.forSale});

  final int total;
  final int free;
  final int forSale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174D2B), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x332E7D32), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Your garden',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _DashboardValue(value: total, label: 'Total')),
              const _VerticalDivider(),
              Expanded(child: _DashboardValue(value: free, label: 'Free')),
              const _VerticalDivider(),
              Expanded(child: _DashboardValue(value: forSale, label: 'For sale')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardValue extends StatelessWidget {
  const _DashboardValue({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 12)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: const Color(0x40FFFFFF));
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFFE5F4E7),
      side: BorderSide(color: selected ? const Color(0xFF2E7D32) : const Color(0xFFDDE7DE)),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF2E7D32) : const Color(0xFF69806E),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.white,
      showCheckmark: false,
    );
  }
}

class _PlantManagementCard extends StatelessWidget {
  const _PlantManagementCard({
    required this.plant,
    required this.isDeleting,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> plant;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = plant['name']?.toString() ?? 'Unknown plant';
    final location = plant['location']?.toString() ?? 'Location not specified';
    final imageUrl = plant['imageUrl']?.toString() ?? '';
    final isFree = plant['isFree'] == true;
    final price = plant['price'] ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isDeleting ? null : onTap,
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
                  width: 88,
                  height: 88,
                  child: imageUrl.isEmpty
                      ? const _ImageFallback()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ImageFallback(),
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF174D2B), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF69806E)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF69806E), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: isFree ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isFree ? 'FREE' : '₹ $price',
                            style: TextStyle(
                              color: isFree ? const Color(0xFF2E7D32) : const Color(0xFFB26A00),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _SmallStat(icon: Icons.favorite_outline_rounded, value: plant['favoriteCount']),
                        const SizedBox(width: 8),
                        _SmallStat(icon: Icons.visibility_outlined, value: plant['views']),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (isDeleting)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF2E7D32)),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Listing actions',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined, color: Color(0xFF2E7D32)),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded, color: Colors.red),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.icon, required this.value});
  final IconData icon;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF69806E)),
        const SizedBox(width: 3),
        Text('${value ?? 0}', style: const TextStyle(color: Color(0xFF69806E), fontSize: 11)),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFE7F3E8),
        alignment: Alignment.center,
        child: const Icon(Icons.local_florist_rounded, color: Color(0xFF2E7D32), size: 42),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAddPlant});
  final VoidCallback onAddPlant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(color: Color(0xFFE7F3E8), shape: BoxShape.circle),
              child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2E7D32), size: 58),
            ),
            const SizedBox(height: 22),
            const Text('No plants yet', style: TextStyle(color: Color(0xFF174D2B), fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Add your first plant and start sharing with the community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF69806E), height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddPlant,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first plant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: Color(0xFF69806E), size: 54),
              SizedBox(height: 12),
              Text('No matching plants found', style: TextStyle(color: Color(0xFF174D2B), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text('Please sign in to view your plants.', textAlign: TextAlign.center),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 54),
            const SizedBox(height: 14),
            const Text('Could not load your plants', style: TextStyle(color: Color(0xFF174D2B), fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            const Text(
              'Please check your connection and Firestore permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF69806E)),
            ),
          ],
        ),
      ),
    );
  }
}
