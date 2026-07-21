// lib/screens/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_list_screen.dart';
import 'package:plantmitra_1/screens/favorites/favorite_screen.dart';
import 'package:plantmitra_1/screens/home/all_plants_screen.dart';
import 'package:plantmitra_1/screens/profile/profile_screen.dart';
import 'package:plantmitra_1/services/plant_count_service.dart';
import 'package:plantmitra_1/services/plant_master_service.dart';
import 'package:plantmitra_1/services/session_service.dart';
import 'package:plantmitra_1/theme/app_colors.dart';
import 'package:plantmitra_1/theme/app_text_styles.dart';
import 'package:plantmitra_1/utils/logger.dart';
import 'package:plantmitra_1/widgets/session_listener.dart';

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
  String? _errorMessage;
  int _selectedIndex = 0;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _firstName {
    final displayName = _currentUser?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }

    final email = _currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Plant Lover';
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _masterService.loadPlants();
      Logger.debug('Master plants loaded: ${_masterService.plants.length}');

      final counts = await _countService.getAllCounts();

      if (!mounted) return;
      setState(() {
        _counts = counts;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      Logger.error('Error loading home data: $error\n$stackTrace');

      if (!mounted) return;
      setState(() {
        _errorMessage = 'We could not load your plant dashboard.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCounts() async {
    try {
      final counts = await _countService.getAllCounts();

      if (!mounted) return;
      setState(() {
        _counts = counts;
        _errorMessage = null;
      });
    } catch (error, stackTrace) {
      Logger.error('Error refreshing counts: $error\n$stackTrace');

      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to refresh the latest plant counts.';
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error),
              SizedBox(width: 12),
              Text('Log out'),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out from Jarvis Green?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (error, stackTrace) {
      Logger.error('Logout failed: $error\n$stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Future<void> _openScreen(Widget screen) async {
    _sessionService.resetTimer();

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    if (!mounted) return;
    setState(() => _selectedIndex = 0);
    await _refreshCounts();
  }

  void _openAllPlants({required String title, bool? isFree}) {
    _openScreen(AllPlantsScreen(title: title, isFree: isFree));
  }

  void _handleNavigationTap(int index) {
    _sessionService.resetTimer();

    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    setState(() => _selectedIndex = index);

    switch (index) {
      case 1:
        _openScreen(const AllPlantsScreen(title: 'All Plants'));
        break;
      case 2:
        _openScreen(const FavoriteScreen());
        break;
      case 3:
        _openScreen(const ProfileScreen());
        break;
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
          if (!didPop) {
            await _showLogoutDialog();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jarvis Green',
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.primary,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grow. Share. Connect.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  _sessionService.resetTimer();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshCounts,
            child: _buildBody(
              totalCount: totalCount,
              freeCount: freeCount,
              forSaleCount: forSaleCount,
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openScreen(const AddPlantScreen()),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add Plant',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _handleNavigationTap,
            backgroundColor: AppColors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.14),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_florist_outlined),
                selectedIcon: Icon(Icons.local_florist_rounded),
                label: 'Plants',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required int totalCount,
    required int freeCount,
    required int forSaleCount,
  }) {
    if (_isLoading) {
      return const _HomeLoadingView();
    }

    if (_errorMessage != null && _counts.isEmpty) {
      return _HomeErrorView(message: _errorMessage!, onRetry: _loadData);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _buildGreeting(),
        const SizedBox(height: 18),
        _buildSearchBar(),
        const SizedBox(height: 14),
        _buildDashboardCard(
          totalCount: totalCount,
          freeCount: freeCount,
          forSaleCount: forSaleCount,
        ),
        const SizedBox(height: 18),
        _buildSectionHeader(
          title: 'Explore plants',
          subtitle: 'Discover plants shared by the community',
        ),
        const SizedBox(height: 12),
        _buildExploreGrid(
          totalCount: totalCount,
          freeCount: freeCount,
          forSaleCount: forSaleCount,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 18),
          _buildInlineError(),
        ],
      ],
    );
  }

  Widget _buildGreeting() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: _currentUser?.photoURL != null
              ? NetworkImage(_currentUser!.photoURL!)
              : null,
          child: _currentUser?.photoURL == null
              ? const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primary,
                  size: 27,
                )
              : null,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $_firstName 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Let's grow something beautiful today.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openAllPlants(title: 'All Plants'),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search plants, categories or listings',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required int totalCount,
    required int freeCount,
    required int forSaleCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.white, size: 19),
              SizedBox(width: 8),
              Text(
                'Community Garden',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            totalCount.toString(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'plants available to explore',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.84),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardStat(
                  icon: Icons.volunteer_activism_rounded,
                  value: freeCount.toString(),
                  label: 'Free',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardStat(
                  icon: Icons.sell_outlined,
                  value: forSaleCount.toString(),
                  label: 'For sale',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildExploreGrid({
    required int totalCount,
    required int freeCount,
    required int forSaleCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _ExploreCard(
                title: 'All Plants',
                count: totalCount,
                icon: Icons.local_florist_rounded,
                iconColor: AppColors.primary,
                onTap: () => _openAllPlants(title: 'All Plants'),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ExploreCard(
                title: 'Free Plants',
                count: freeCount,
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.success,
                onTap: () => _openAllPlants(title: 'Free Plants', isFree: true),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ExploreCard(
                title: 'For Sale',
                count: forSaleCount,
                icon: Icons.sell_rounded,
                iconColor: AppColors.warning,
                onTap: () =>
                    _openAllPlants(title: 'Plants for Sale', isFree: false),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ExploreCard(
                title: 'Chat',
                count: null,
                icon: Icons.forum_rounded,
                iconColor: AppColors.primaryDark,
                onTap: () => _openScreen(const ChatListScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInlineError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(onPressed: _refreshCounts, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 19),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.78),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.count,
  });

  final String title;
  final int? count;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          height: 142,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count == null ? 'Open conversations' : '$count listings',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: const [
        _SkeletonBox(height: 54, borderRadius: 16),
        SizedBox(height: 18),
        _SkeletonBox(height: 54, borderRadius: 16),
        SizedBox(height: 18),
        _SkeletonBox(height: 215, borderRadius: 24),
        SizedBox(height: 24),
        _SkeletonBox(height: 24, widthFactor: 0.42, borderRadius: 8),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 142, borderRadius: 19)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonBox(height: 142, borderRadius: 19)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    required this.borderRadius,
    this.widthFactor = 1,
  });

  final double height;
  final double borderRadius;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 100, 28, 120),
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.error,
            size: 38,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Dashboard unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
