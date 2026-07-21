// lib/screens/detail/plant_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/screens/chat/chat_screen.dart';
import 'package:plantmitra_1/screens/edit_plant/edit_plant_screen.dart';
import 'package:plantmitra_1/services/chat_service.dart';
import 'package:plantmitra_1/services/favorite_service.dart';
import 'package:plantmitra_1/utils/logger.dart';

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({
    super.key,
    required this.documentId,
    required this.plant,
  });

  final String documentId;
  final Map<String, dynamic> plant;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  static const Color _green = Color(0xFF2E7D32);
  static const Color _darkGreen = Color(0xFF145A32);
  static const Color _pageColor = Color(0xFFF5F8F4);

  final FavoriteService _favoriteService = FavoriteService();
  final ChatService _chatService = ChatService();

  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isChangingFavorite = false;
  bool _isDeleting = false;
  bool _isOwner = false;
  String? _currentUserId;

  Map<String, dynamic> get _plant => widget.plant;

  String _text(String key, [String fallback = '']) {
    final value = _plant[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _number(String key) {
    final value = _plant[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    _checkOwnerStatus();
    await _checkFavoriteStatus();
  }

  void _checkOwnerStatus() {
    final currentUser = _chatService.getCurrentUserId();
    final ownerId = _text('ownerId');

    if (!mounted) return;
    setState(() {
      _currentUserId = currentUser;
      _isOwner = currentUser != null && ownerId.isNotEmpty && currentUser == ownerId;
    });
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await _favoriteService.isFavorite(widget.documentId);
      if (!mounted) return;
      setState(() => _isFavorite = isFavorite);
    } catch (error) {
      Logger.error('Error checking favorite status: $error');
    } finally {
      if (mounted) setState(() => _isCheckingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isCheckingFavorite || _isChangingFavorite) return;

    setState(() => _isChangingFavorite = true);
    try {
      final newStatus =
          await _favoriteService.toggleFavorite(widget.documentId);
      if (!mounted) return;
      setState(() => _isFavorite = newStatus);
      _showMessage(
        newStatus ? 'Added to favorites' : 'Removed from favorites',
      );
    } catch (error) {
      Logger.error('Error toggling favorite: $error');
      if (mounted) {
        _showMessage('Could not update favorites. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isChangingFavorite = false);
    }
  }

  void _startChat() {
    final currentUserId = _currentUserId;
    final ownerId = _text('ownerId');

    if (currentUserId == null || currentUserId.isEmpty) {
      _showMessage('Please log in to chat with the owner.', isError: true);
      return;
    }
    if (ownerId.isEmpty) {
      _showMessage('Owner information is not available.', isError: true);
      return;
    }
    if (currentUserId == ownerId) {
      _showMessage("This is your listing, so you can't chat with yourself.");
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          senderId: currentUserId,
          receiverId: ownerId,
          receiverName: _text('ownerName', 'Seller'),
          receiverImage: _plant['ownerPhoto']?.toString(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (!_isOwner || _isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        title: const Text('Delete this plant?'),
        content: const Text(
          'This listing will be permanently deleted. This action cannot be undone.',
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

    if (shouldDelete == true) await _deletePlant();
  }

  Future<void> _deletePlant() async {
    if (!_isOwner || _isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('plants')
          .doc(widget.documentId)
          .delete();

      if (!mounted) return;
      _showMessage('Plant deleted successfully.');
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      Logger.error('Firebase error deleting plant: ${error.code} - ${error.message}');
      if (mounted) {
        final message = error.code == 'permission-denied'
            ? 'You do not have permission to delete this plant.'
            : 'Could not delete the plant. Please try again.';
        _showMessage(message, isError: true);
      }
    } catch (error) {
      Logger.error('Error deleting plant: $error');
      if (mounted) {
        _showMessage('Could not delete the plant. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _sharePlant() {
    _showMessage('Share functionality is coming soon.');
  }

  Future<void> _showReportDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.flag_outlined, color: Colors.orange),
        title: const Text('Report listing?'),
        content: const Text(
          'Report this listing if it looks misleading, unsafe, or inappropriate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _showMessage('Report received. We will review this listing.');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
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

  Future<void> _openEditPlant() async {
    if (!_isOwner || _isDeleting) return;

    final updatedPlant = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EditPlantScreen(
          documentId: widget.documentId,
          plant: Map<String, dynamic>.from(widget.plant),
        ),
      ),
    );

    if (!mounted || updatedPlant == null) return;
    setState(() {
      widget.plant
        ..clear()
        ..addAll(updatedPlant);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _text('name', 'Unknown Plant');
    final scientificName = _text('scientificName');
    final imageUrl = _text('imageUrl');
    final category = _text('category', 'Uncategorized');
    final subCategory = _text('subCategory');
    final itemType = _text('itemType', 'Plant');
    final description = _text('description');
    final location = _text('location', 'Location not specified');
    final ownerName = _text('ownerName', 'Unknown Owner');
    final ownerPhoto = _text('ownerPhoto');
    final isFree = _plant['isFree'] == true;
    final price = _plant['price'] ?? 0;

    return Scaffold(
      backgroundColor: _pageColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            stretch: true,
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
                onPressed: (_isCheckingFavorite || _isChangingFavorite)
                    ? null
                    : _toggleFavorite,
                icon: (_isCheckingFavorite || _isChangingFavorite)
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite ? Colors.red.shade300 : Colors.white,
                      ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PlantImage(imageUrl: imageUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF17351E),
                                  ),
                            ),
                            if (scientificName.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                scientificName,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade700,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _PriceBadge(isFree: isFree, price: price),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(label: category, icon: Icons.category_outlined),
                      if (subCategory.isNotEmpty)
                        _Tag(label: subCategory, icon: Icons.eco_outlined),
                      if (itemType.isNotEmpty && itemType != 'Plant')
                        _Tag(label: itemType, icon: Icons.inventory_2_outlined),
                      if (_isOwner)
                        const _Tag(label: 'Your listing', icon: Icons.person_outline),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: _green.withValues(alpha: 0.12),
                          backgroundImage:
                              ownerPhoto.isNotEmpty ? NetworkImage(ownerPhoto) : null,
                          child: ownerPhoto.isEmpty
                              ? Text(
                                  ownerName.isNotEmpty
                                      ? ownerName.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOwner ? 'Posted by you' : 'Posted by',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ownerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isOwner)
                          TextButton(
                            onPressed: _startChat,
                            child: const Text('Contact'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on_outlined, color: _green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                location,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('About this plant'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 15, height: 1.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle('Listing activity'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.favorite_outline_rounded,
                          value: _number('favoriteCount'),
                          label: 'Favorites',
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.visibility_outlined,
                          value: _number('views'),
                          label: 'Views',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          value: _number('chatCount'),
                          label: 'Chats',
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_isOwner)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _startChat,
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text(
                          'Chat with owner',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (_isOwner) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isDeleting ? null : _openEditPlant,
                        style: FilledButton.styleFrom(backgroundColor: _green),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(
                          'Edit plant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : _confirmDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: _isDeleting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Text(_isDeleting ? 'Deleting...' : 'Delete plant'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sharePlant,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share this plant'),
                    ),
                  ),
                  if (!_isOwner)
                    Center(
                      child: TextButton.icon(
                        onPressed: _showReportDialog,
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: const Text('Report this listing'),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantImage extends StatelessWidget {
  const _PlantImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const _ImagePlaceholder();

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const _ImagePlaceholder(showLoader: true);
          },
          errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Colors.transparent, Color(0x55000000)],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.showLoader = false});

  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDCEEDB),
      child: Center(
        child: showLoader
            ? const CircularProgressIndicator(color: Color(0xFF2E7D32))
            : const Icon(
                Icons.local_florist_rounded,
                size: 92,
                color: Color(0xFF2E7D32),
              ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.isFree, required this.price});

  final bool isFree;
  final dynamic price;

  @override
  Widget build(BuildContext context) {
    final color = isFree ? const Color(0xFF2E7D32) : const Color(0xFFB26A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isFree ? 'FREE' : '₹ $price',
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6DC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E9E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF17351E),
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E9E1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
