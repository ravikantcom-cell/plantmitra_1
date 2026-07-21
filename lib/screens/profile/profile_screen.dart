// lib/screens/profile/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plantmitra_1/screens/admin/upload_master_plants_screen.dart';
import 'package:plantmitra_1/screens/about/about_screen.dart';
import 'package:plantmitra_1/screens/add_plant/add_plant_screen.dart';
import 'package:plantmitra_1/screens/chat/chat_list_screen.dart';
import 'package:plantmitra_1/screens/favorites/favorite_screen.dart';
import 'package:plantmitra_1/screens/my_plants/my_plants_screen.dart';
import 'package:plantmitra_1/screens/settings/notification_settings_screen.dart';
import 'package:plantmitra_1/screens/settings/settings_screen.dart';
import 'package:plantmitra_1/services/public_profile_service.dart';
import 'package:plantmitra_1/utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _secondaryText = Color(0xFF69806E);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoggingOut = false;
  bool _isUpdatingProfile = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    PublicProfileService.instance.ensureCurrentUserProfile();
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your plants, favorites and chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) await _logout();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      // Sign out from both Firebase and Google so account selection works
      // correctly on the next login.
      try {
        await GoogleSignIn().signOut();
      } catch (error) {
        Logger.warning('Google sign-out warning: $error');
      }
      await _auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (error) {
      Logger.error('Logout failed: $error');
      if (mounted) {
        _showMessage('Could not log out. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _showEditProfileDialog() async {
    final user = _user;
    if (user == null || _isUpdatingProfile) return;

    var editedName = user.displayName ?? '';
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.person_outline_rounded, color: _green),
        title: const Text('Edit profile'),
        content: TextFormField(
          initialValue: editedName,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Display name',
            prefixIcon: const Icon(Icons.badge_outlined, color: _green),
            filled: true,
            fillColor: const Color(0xFFF7FAF7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onChanged: (value) => editedName = value,
          onFieldSubmitted: (value) =>
              Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, editedName.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().length < 2) {
      if (newName != null && mounted) {
        _showMessage('Please enter a valid name.', isError: true);
      }
      return;
    }
    await _updateProfileName(newName.trim());
  }

  Future<void> _updateProfileName(String name) async {
    final user = _user;
    if (user == null) return;
    setState(() => _isUpdatingProfile = true);

    try {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': name,
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.reload();
      await PublicProfileService.instance.ensureCurrentUserProfile();

      if (!mounted) return;
      setState(() => _user = _auth.currentUser);
      _showMessage('Profile updated successfully.');
    } catch (error) {
      Logger.error('Profile update failed: $error');
      if (mounted) {
        _showMessage(
          'Could not update your profile. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
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
    final user = _user;
    if (user == null) return const _SignedOutProfile();
    final isAdmin =
        user.email?.trim().toLowerCase() == 'ravikant.com@gmail.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF5FBF5), Color(0xFFEAF7EC)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    _ProfileHeader(
                      user: user,
                      isUpdating: _isUpdatingProfile,
                      onEdit: _showEditProfileDialog,
                    ),
                    const SizedBox(height: 16),
                    _PlantCountCard(
                      uid: user.uid,
                      onTap: () => _openScreen(const MyPlantsScreen()),
                    ),
                    const SizedBox(height: 18),
                    const _SectionLabel('Your garden'),
                    const SizedBox(height: 9),
                    _MenuGroup(
                      children: [
                        _ProfileMenuTile(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Add New Plant',
                          subtitle: 'Share a plant with the community',
                          onTap: () => _openScreen(const AddPlantScreen()),
                        ),
                        _ProfileMenuTile(
                          icon: Icons.favorite_border_rounded,
                          title: 'My Favorites',
                          subtitle: 'Plants you have saved',
                          onTap: () => _openScreen(const FavoriteScreen()),
                        ),
                        _ProfileMenuTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'My Chats',
                          subtitle: 'Your plant conversations',
                          onTap: () => _openScreen(const ChatListScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _SectionLabel('Account'),
                    const SizedBox(height: 9),
                    _MenuGroup(
                      children: [
                        _ProfileMenuTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Manage notification preferences',
                          onTap: () =>
                              _openScreen(const NotificationSettingsScreen()),
                        ),
                        _ProfileMenuTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'App preferences and privacy',
                          onTap: () => _openScreen(const SettingsScreen()),
                        ),
                        _ProfileMenuTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About Jarvis Green',
                          subtitle: 'Version 1.0.0',
                          onTap: () => _openScreen(const AboutScreen()),
                        ),
                      ],
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 18),
                      const _SectionLabel('Admin tools'),
                      const SizedBox(height: 9),
                      _MenuGroup(
                        children: [
                          _ProfileMenuTile(
                            icon: Icons.cloud_upload_outlined,
                            title: 'Upload Plant Master',
                            subtitle: 'Import and update the plant database',
                            onTap: () =>
                                _openScreen(const UploadMasterPlantsScreen()),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoggingOut ? null : _confirmLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isLoggingOut
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                          _isLoggingOut ? 'Logging out...' : 'Log out',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isUpdating,
    required this.onEdit,
  });

  final User user;
  final bool isUpdating;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = (user.displayName ?? '').trim().isEmpty
        ? 'Plant Lover'
        : user.displayName!.trim();
    final photoUrl = user.photoURL?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0ECE1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12174D2B),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF80C783)],
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -4,
                bottom: 2,
                child: Material(
                  color: const Color(0xFF2E7D32),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: isUpdating ? null : onEdit,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF174D2B),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isUpdating) ...[
                const SizedBox(width: 8),
                const SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            user.email ?? 'No email available',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF69806E), fontSize: 13),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 16),
                SizedBox(width: 5),
                Text(
                  'Jarvis Green Member',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _PlantCountCard extends StatelessWidget {
  const _PlantCountCard({required this.uid, required this.onTap});
  final String uid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('plants')
          .where('ownerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length;
        return Material(
          color: const Color(0xFF174D2B),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.local_florist_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My plant listings',
                          style: TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count == null
                              ? 'Loading…'
                              : '$count ${count == 1 ? 'plant' : 'plants'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF174D2B),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE0E9E1)),
    ),
    child: Column(children: children),
  );
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF263B2B),
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: Color(0xFF69806E), fontSize: 11),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA99D)),
  );
}

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              color: Color(0xFF69806E),
              size: 58,
            ),
            const SizedBox(height: 14),
            const Text('Please sign in to view your profile.'),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false),
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    ),
  );
}
