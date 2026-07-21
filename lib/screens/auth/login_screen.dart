// lib/screens/auth/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plantmitra_1/constants/app_assets.dart';
import 'package:plantmitra_1/screens/auth/email_login_screen.dart';
import 'package:plantmitra_1/utils/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _textSecondary = Color(0xFF69806E);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = _auth.currentUser;
    if (user == null || !mounted || _hasNavigated) return;

    await _saveUserData(user);
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _saveUserData(User user) async {
    try {
      final reference = _firestore.collection('users').doc(user.uid);
      final snapshot = await reference.get();

      final data = <String, dynamic>{
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Keep the original account creation time instead of replacing it on
      // every login.
      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await reference.set(data, SetOptions(merge: true));
      Logger.info('User data saved for ${user.uid}');
    } catch (error) {
      // A profile-write failure should not block a successful Firebase login.
      Logger.error('Error saving user data: $error');
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final googleUser = await _googleSignIn.signIn();

      // Closing the Google account picker is not an error.
      if (googleUser == null) return;

      final googleAuthentication = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuthentication.accessToken,
        idToken: googleAuthentication.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Google sign-in completed without a user account.',
        );
      }

      await _saveUserData(user);
      if (!mounted || _hasNavigated) return;

      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (error) {
      Logger.error('Firebase Google sign-in error: ${error.code}');
      if (mounted) _showError(_friendlyAuthMessage(error));
    } catch (error) {
      Logger.error('Google sign-in error: $error');
      if (mounted) {
        _showError('Google sign-in failed. Please check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'account-exists-with-different-credential':
        return 'This email is already registered using another sign-in method.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled for this app.';
      default:
        return error.message ?? 'Google sign-in failed. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openEmailLogin() {
    if (_isLoading) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF6),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5FBF5),
              Color(0xFFEAF7EC),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 52,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Spacer(),
                        _buildLogo(),
                        const SizedBox(height: 35),
                        const Text(
                          'Welcome to Jarvis Green',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _darkGreen,
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Grow, share and connect with plant lovers near you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 34),
                        _buildLoginCard(),
                        const Spacer(),
                        const SizedBox(height: 24),
                        const Text(
                          'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 250,
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9EEDC), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F18864B),
            blurRadius: 28,
            spreadRadius: 2,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          AppAssets.logo,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF0F8F1),
              alignment: Alignment.center,
              child: const Icon(Icons.eco_rounded, color: _green, size: 72),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0ECE1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F174D2B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF243128),
                disabledBackgroundColor: const Color(0xFFF3F5F3),
                side: const BorderSide(color: Color(0xFFD8E2D9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _green,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppAssets.googleLogo,
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_circle_outlined,
                            color: _green,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFDDE7DE))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFDDE7DE))),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _openEmailLogin,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _green.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.mail_outline_rounded, size: 21),
              label: const Text(
                'Sign in with Email',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
