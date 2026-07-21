// lib/screens/settings/notification_settings_screen.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/notification_service.dart';
import 'package:plantmitra_1/utils/logger.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);

  final NotificationService _service = NotificationService.instance;
  NotificationPreferences _preferences = const NotificationPreferences();
  AuthorizationStatus _permissionStatus = AuthorizationStatus.notDetermined;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        _service.loadPreferences(),
        _service.permissionStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _preferences = results[0] as NotificationPreferences;
        _permissionStatus = results[1] as AuthorizationStatus;
      });
    } catch (error) {
      Logger.error('Notification settings load failed: $error');
      if (mounted) _message('Could not load notification settings.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save(NotificationPreferences next) async {
    if (_isSaving) return;
    final previous = _preferences;
    setState(() {
      _preferences = next;
      _isSaving = true;
    });
    try {
      await _service.savePreferences(next);
      final status = await _service.permissionStatus();
      if (mounted) setState(() => _permissionStatus = status);
    } catch (error) {
      Logger.error('Notification settings save failed: $error');
      if (!mounted) return;
      setState(() => _preferences = previous);
      _message('Could not save notification settings.', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _permissionLabel {
    switch (_permissionStatus) {
      case AuthorizationStatus.authorized:
        return 'Allowed by device';
      case AuthorizationStatus.provisional:
        return 'Provisionally allowed';
      case AuthorizationStatus.denied:
        return 'Blocked by device';
      case AuthorizationStatus.notDetermined:
        return 'Permission not requested';
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade700 : _darkGreen,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _green),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_darkGreen, _green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          color: Colors.white, size: 34),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Device permission',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(_permissionLabel,
                                style: const TextStyle(
                                    color: Color(0xD9FFFFFF), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsGroup(children: [
                  _SwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Allow notifications',
                    subtitle: 'Master control for Jarvis Green alerts',
                    value: _preferences.enabled,
                    enabled: !_isSaving,
                    onChanged: (value) =>
                        _save(_preferences.copyWith(enabled: value)),
                  ),
                ]),
                const SizedBox(height: 16),
                _SettingsGroup(children: [
                  _SwitchTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat messages',
                    subtitle: 'Alerts when someone messages you',
                    value: _preferences.chatMessages,
                    enabled: _preferences.enabled && !_isSaving,
                    onChanged: (value) =>
                        _save(_preferences.copyWith(chatMessages: value)),
                  ),
                  _SwitchTile(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Listing activity',
                    subtitle: 'Favorites and activity on your listings',
                    value: _preferences.listingActivity,
                    enabled: _preferences.enabled && !_isSaving,
                    onChanged: (value) =>
                        _save(_preferences.copyWith(listingActivity: value)),
                  ),
                  _SwitchTile(
                    icon: Icons.near_me_outlined,
                    title: 'Nearby plants',
                    subtitle: 'New plant listings near your location',
                    value: _preferences.nearbyPlants,
                    enabled: _preferences.enabled && !_isSaving,
                    onChanged: (value) =>
                        _save(_preferences.copyWith(nearbyPlants: value)),
                  ),
                  _SwitchTile(
                    icon: Icons.campaign_outlined,
                    title: 'News and updates',
                    subtitle: 'Occasional Jarvis Green announcements',
                    value: _preferences.marketing,
                    enabled: _preferences.enabled && !_isSaving,
                    onChanged: (value) =>
                        _save(_preferences.copyWith(marketing: value)),
                  ),
                ]),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Your preferences are saved to your Jarvis Green account. '
                    'Device-level permission may also need to be enabled in Android settings.',
                    style: TextStyle(color: Color(0xFF69806E), fontSize: 11, height: 1.45),
                  ),
                ),
              ],
            ),
    );
  }
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 21),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Color(0xFF263B2B), fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Color(0xFF69806E), fontSize: 11)),
        value: value,
        activeThumbColor: const Color(0xFF2E7D32),
        onChanged: enabled ? onChanged : null,
      );
}
