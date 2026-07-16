import 'package:flutter/material.dart';
import 'package:plantmitra_1/services/session_service.dart';

/// A widget that listens to user interactions and resets the session timer
class SessionListener extends StatefulWidget {
  final Widget child;

  const SessionListener({
    super.key,
    required this.child,
  });

  @override
  State<SessionListener> createState() => _SessionListenerState();
}

class _SessionListenerState extends State<SessionListener> {
  final SessionService _sessionService = SessionService();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _sessionService.resetTimer(), // No parameter
      onPanDown: (_) => _sessionService.resetTimer(), // Has parameter, we ignore it
      onScaleStart: (_) => _sessionService.resetTimer(), // Has parameter, we ignore it
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}