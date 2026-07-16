import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  
  SessionService._internal();

  Timer? _inactivityTimer;
  final Duration _timeoutDuration = const Duration(minutes: 30); // 30 minutes
  
  VoidCallback? _onSessionExpired;
  bool _isTimerRunning = false;

  void initialize(VoidCallback onSessionExpired) {
    _onSessionExpired = onSessionExpired;
    _resetTimer();
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen to user interactions
    WidgetsBinding.instance.addObserver(
      _WidgetsBindingObserver(this),
    );
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, () {
      _handleSessionTimeout();
    });
    _isTimerRunning = true;
  }

  void _handleSessionTimeout() {
    if (_onSessionExpired != null) {
      _onSessionExpired!();
    }
    _isTimerRunning = false;
  }

  void resetTimer() {
    if (_isTimerRunning) {
      _resetTimer();
    }
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _isTimerRunning = false;
  }

  // Called when user interacts with the app
  void onUserInteraction() {
    resetTimer();
  }

  // Manual logout
  Future<void> logout() async {
    _inactivityTimer?.cancel();
    _isTimerRunning = false;
    await FirebaseAuth.instance.signOut();
  }
}

// WidgetsBindingObserver to detect user interactions
class _WidgetsBindingObserver extends WidgetsBindingObserver {
  final SessionService _sessionService;

  _WidgetsBindingObserver(this._sessionService);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset timer when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _sessionService.resetTimer();
    }
    // Pause timer when app goes to background
    if (state == AppLifecycleState.paused) {
      // Optionally pause or keep running
    }
  }

  @override
  void didHaveMemoryPressure() {
    // Handle memory pressure if needed
  }
}