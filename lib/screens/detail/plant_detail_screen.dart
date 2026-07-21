// lib/screens/detail/plant_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plantmitra_1/screens/chat/chat_screen.dart';
import 'package:plantmitra_1/screens/edit_plant/edit_plant_screen.dart';
import 'package:plantmitra_1/services/chat_service.dart';
import 'package:plantmitra_1/services/favorite_service.dart';
import 'package:plantmitra_1/services/plant_transfer_service.dart';
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
  final PlantTransferService _transferService = PlantTransferService();

  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isChangingFavorite = false;
  bool _isDeleting = false;
  bool _isTransferActionRunning = false;
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
      _isOwner =
          currentUser != null && ownerId.isNotEmpty && currentUser == ownerId;
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
      final newStatus = await _favoriteService.toggleFavorite(
        widget.documentId,
      );
      if (!mounted) return;
      setState(() => _isFavorite = newStatus);
      _showMessage(newStatus ? 'Added to favorites' : 'Removed from favorites');
    } catch (error) {
      Logger.error('Error toggling favorite: $error');
      if (mounted) {
        _showMessage(
          'Could not update favorites. Please try again.',
          isError: true,
        );
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
          plantId: widget.documentId,
          plantName: _text('name', 'Plant listing'),
          plantImage: _plant['imageUrl']?.toString(),
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
      Logger.error(
        'Firebase error deleting plant: ${error.code} - ${error.message}',
      );
      if (mounted) {
        final message = error.code == 'permission-denied'
            ? 'You do not have permission to delete this plant.'
            : 'Could not delete the plant. Please try again.';
        _showMessage(message, isError: true);
      }
    } catch (error) {
      Logger.error('Error deleting plant: $error');
      if (mounted) {
        _showMessage(
          'Could not delete the plant. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _sharePlant() async {
    final name = _text('name', 'Plant listing');
    final scientificName = _text('scientificName');
    final location = _text('location', 'Location not specified');
    final isFree = _plant['isFree'] == true;
    final price = _plant['price'] ?? 0;
    final ownerName = _text('ownerName', 'Jarvis Green member');

    final lines = <String>[
      '🌿 $name',
      if (scientificName.isNotEmpty) scientificName,
      isFree ? 'Available for free' : 'Price: ₹$price',
      'Location: $location',
      'Shared by $ownerName on Jarvis Green',
      'Listing ID: ${widget.documentId}',
    ];

    try {
      await Clipboard.setData(ClipboardData(text: lines.join('\n')));
      if (mounted) {
        _showMessage('Plant details copied. Paste them into any app to share.');
      }
    } catch (error) {
      Logger.error('Share plant error: $error');
      if (mounted) {
        _showMessage('Could not copy the plant details.', isError: true);
      }
    }
  }

  Future<void> _showReportDialog() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Row(
          children: [
            Icon(Icons.flag_outlined, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Why are you reporting this listing?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        children: [
          for (final option in const <String>[
            'Misleading information',
            'Unsafe or prohibited plant',
            'Spam or duplicate listing',
            'Inappropriate content',
            'Other concern',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, option),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(option),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 7),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );

    if (reason == null || !mounted) return;
    await _submitReport(reason);
  }

  Future<void> _submitReport(String reason) async {
    final reporterId = _currentUserId;
    if (reporterId == null || reporterId.isEmpty) {
      _showMessage('Please sign in before reporting a listing.', isError: true);
      return;
    }

    final ownerId = _text('ownerId');
    if (ownerId == reporterId) {
      _showMessage('You cannot report your own listing.', isError: true);
      return;
    }

    try {
      final reportId = '${reporterId}_${widget.documentId}';
      await FirebaseFirestore.instance.collection('reports').doc(reportId).set({
        'reporterId': reporterId,
        'plantId': widget.documentId,
        'plantOwnerId': ownerId,
        'plantName': _text('name', 'Unknown plant'),
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showMessage('Report received. We will review this listing.');
      }
    } on FirebaseException catch (error) {
      Logger.error(
        'Report submission failed: ${error.code} - ${error.message}',
      );
      if (mounted) {
        final message = error.code == 'permission-denied'
            ? 'Reporting is not permitted. Please update Firestore rules.'
            : 'Could not submit the report. Please try again.';
        _showMessage(message, isError: true);
      }
    } catch (error) {
      Logger.error('Report submission failed: $error');
      if (mounted) {
        _showMessage(
          'Could not submit the report. Please try again.',
          isError: true,
        );
      }
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

  Future<void> _runTransferAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_isTransferActionRunning) return;
    setState(() => _isTransferActionRunning = true);
    try {
      await action();
      if (mounted) _showMessage(successMessage);
    } catch (error) {
      Logger.error('Plant transfer action failed: $error');
      if (mounted) {
        final message = error is StateError
            ? error.message.toString()
            : 'Could not update this request. Please try again.';
        _showMessage(message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isTransferActionRunning = false);
    }
  }

  Widget _buildTransferSection({required bool isFree}) {
    if (!isFree) return const SizedBox.shrink();

    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isOwner) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _transferService.incomingRequests(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _TransferNotice(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load plant requests',
              subtitle: 'Please check your connection and try again.',
              color: Colors.red,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = (snapshot.data?.docs ?? const [])
              .where((doc) => doc.data()['plantId'] == widget.documentId)
              .where(
                (doc) =>
                    doc.data()['status'] == 'requested' ||
                    doc.data()['status'] == 'approved',
              )
              .toList();

          if (requests.isEmpty) {
            return const _TransferNotice(
              icon: Icons.volunteer_activism_outlined,
              title: 'No requests yet',
              subtitle: 'Interested members can request this free plant.',
              color: _green,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Plant requests'),
              const SizedBox(height: 10),
              ...requests.map((doc) {
                final request = doc.data();
                final isApproved = request['status'] == 'approved';
                final receiverName =
                    (request['receiverName'] ?? 'Community member').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransferRequestCard(
                    receiverName: receiverName,
                    isApproved: isApproved,
                    isBusy: _isTransferActionRunning,
                    onApprove: () => _runTransferAction(
                      () => _transferService.approveRequest(doc.id),
                      'Request approved. Waiting for receiver confirmation.',
                    ),
                    onReject: () => _runTransferAction(
                      () => _transferService.rejectRequest(doc.id),
                      'Request rejected.',
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _transferService.transferForPlant(
        widget.documentId,
        currentUserId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _TransferNotice(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load request status',
            subtitle: 'Please check your connection and try again.',
            color: Colors.red,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();
        final status = (data?['status'] ?? '').toString();

        if (status == 'requested') {
          return _TransferActionCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Request sent',
            subtitle: 'Waiting for the plant owner to approve it.',
            buttonLabel: 'Cancel request',
            isBusy: _isTransferActionRunning,
            outlined: true,
            onPressed: () => _runTransferAction(
              () => _transferService.cancelRequest(snapshot.data!.id),
              'Request cancelled.',
            ),
          );
        }

        if (status == 'approved') {
          return _TransferActionCard(
            icon: Icons.handshake_outlined,
            title: 'Request approved',
            subtitle: 'Confirm only after you have received the plant.',
            buttonLabel: 'Confirm plant received',
            isBusy: _isTransferActionRunning,
            onPressed: () => _runTransferAction(
              () => _transferService.confirmReceived(snapshot.data!.id),
              'Plant received. Your record has been updated.',
            ),
          );
        }

        if (status == 'completed') {
          return const _TransferNotice(
            icon: Icons.verified_rounded,
            title: 'Plant received',
            subtitle: 'This transfer is complete and recorded.',
            color: _green,
          );
        }

        return _TransferActionCard(
          icon: Icons.volunteer_activism_outlined,
          title: 'Interested in this free plant?',
          subtitle: 'Send a request to the owner. No payment is involved.',
          buttonLabel: 'Request this plant',
          isBusy: _isTransferActionRunning,
          onPressed: () => _runTransferAction(
            () => _transferService.requestFreePlant(
              plantId: widget.documentId,
              plant: widget.plant,
            ),
            'Request sent to the plant owner.',
          ),
        );
      },
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
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF17351E),
                                  ),
                            ),
                            if (scientificName.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                scientificName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
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
                        const _Tag(
                          label: 'Your listing',
                          icon: Icons.person_outline,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: _green.withValues(alpha: 0.12),
                          backgroundImage: ownerPhoto.isNotEmpty
                              ? NetworkImage(ownerPhoto)
                              : null,
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
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: _green,
                          ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                  _buildTransferSection(isFree: isFree),
                  if (isFree) const SizedBox(height: 16),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          _isDeleting ? 'Deleting...' : 'Delete plant',
                        ),
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
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
              colors: [
                Color(0x66000000),
                Colors.transparent,
                Color(0x55000000),
              ],
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
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

class _TransferNotice extends StatelessWidget {
  const _TransferNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF17351E),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF69806E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferActionCard extends StatelessWidget {
  const _TransferActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.isBusy,
    required this.onPressed,
    this.outlined = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool isBusy;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final buttonChild = isBusy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(buttonLabel);

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF17351E),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF69806E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: outlined
                ? OutlinedButton(
                    onPressed: isBusy ? null : onPressed,
                    child: buttonChild,
                  )
                : FilledButton(
                    onPressed: isBusy ? null : onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: buttonChild,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransferRequestCard extends StatelessWidget {
  const _TransferRequestCard({
    required this.receiverName,
    required this.isApproved,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final String receiverName;
  final bool isApproved;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE4F3E6),
                foregroundColor: const Color(0xFF2E7D32),
                child: Text(
                  receiverName.isEmpty ? '?' : receiverName[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiverName,
                      style: const TextStyle(
                        color: Color(0xFF17351E),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isApproved
                          ? 'Approved · waiting for confirmation'
                          : 'Wants to receive this plant',
                      style: const TextStyle(
                        color: Color(0xFF69806E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isApproved) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy ? null : onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
