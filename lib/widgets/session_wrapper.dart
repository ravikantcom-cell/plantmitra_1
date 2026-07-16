import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/session_service.dart';

class SessionWrapper extends StatefulWidget {
  final Widget child;

  const SessionWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  final SessionService _sessionService = SessionService();
  bool _isSessionActive = true;

  @override
  void initState() {
    super.initState();
    _sessionService.initialize(_onSessionExpired);
    
    // Setup gesture detector for user interactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupGestureDetector();
    });
  }

  void _setupGestureDetector() {
    // This will catch all taps and scrolls
    // We'll use a custom GestureDetector in the widget tree
  }

  void _onSessionExpired() {
    if (!mounted) return;
    
    setState(() {
      _isSessionActive = false;
    });
    
    _sessionService.logout().then((_) {
      if (mounted) {
        // Show dialog or navigate to login
        _showSessionExpiredDialog();
      }
    });
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your session has expired due to inactivity. Please login again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _sessionService.dispose();
    super.dispose();
  }
}