// lib/screens/settings/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plantmitra_1/screens/settings/notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);

  LocationPermission? _locationPermission;
  bool _checkingLocation = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _locationPermission = permission;
        _checkingLocation = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _checkingLocation = true);
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    if (mounted) {
      setState(() {
        _locationPermission = permission;
        _checkingLocation = false;
      });
    }
  }

  String get _locationStatus {
    if (_checkingLocation) return 'Checking…';
    switch (_locationPermission) {
      case LocationPermission.always:
        return 'Always allowed';
      case LocationPermission.whileInUse:
        return 'Allowed while using app';
      case LocationPermission.deniedForever:
        return 'Blocked in device settings';
      case LocationPermission.denied:
        return 'Not allowed';
      case LocationPermission.unableToDetermine:
      case null:
        return 'Unable to determine';
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  void _showInformation(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          _AccountCard(
            name: user?.displayName ?? 'Jarvis Green Member',
            email: user?.email ?? 'No email available',
          ),
          const SizedBox(height: 20),
          const _SectionTitle('App preferences'),
          const SizedBox(height: 9),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Messages, listings and nearby plants',
              onTap: _openNotifications,
            ),
            _SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'Location access',
              subtitle: _locationStatus,
              loading: _checkingLocation,
              onTap: _requestLocationPermission,
            ),
          ]),
          const SizedBox(height: 20),
          const _SectionTitle('Legal and support'),
          const SizedBox(height: 9),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How Jarvis Green handles your information',
              onTap: () => _showInformation(
                'Privacy Policy',
                'Jarvis Green stores account, plant listing, favorite, chat and '
                    'notification-preference data required to provide the app. '
                    'Before public release, replace this summary with your final '
                    'reviewed Privacy Policy and its official web link.',
              ),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Community and marketplace terms',
              onTap: () => _showInformation(
                'Terms of Service',
                'Users are responsible for the accuracy and legality of their '
                    'plant listings and conversations. Before public release, '
                    'replace this summary with your final reviewed Terms of Service.',
              ),
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About Jarvis Green',
              subtitle: 'Version 1.0.0 (1)',
              onTap: () => _showInformation(
                'Jarvis Green',
                'Version 1.0.0 (1)\n\nGrow • Share • Connect\n\n'
                    'Your smart plant companion and community marketplace.',
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.name, required this.email});
  final String name;
  final String email;

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
            const CircleAvatar(
              radius: 27,
              backgroundColor: Color(0x2BFFFFFF),
              child: Icon(Icons.eco_rounded, color: Colors.white, size: 29),
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
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xD9FFFFFF), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Color(0xFF174D2B), fontSize: 17, fontWeight: FontWeight.w800));
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: loading ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Color(0xFF263B2B), fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Color(0xFF69806E), fontSize: 11)),
        trailing: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF2E7D32)),
              )
            : const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9AA99D)),
      );
}
