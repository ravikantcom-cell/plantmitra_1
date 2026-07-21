// lib/screens/auth/email_login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/constants/app_assets.dart';
import 'package:plantmitra_1/utils/logger.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  static const Color _darkGreen = Color(0xFF174D2B);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _secondaryText = Color(0xFF69806E);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData(User user) async {
    try {
      final reference = _firestore.collection('users').doc(user.uid);
      final snapshot = await reference.get();
      final enteredName = _nameController.text.trim();

      final data = <String, dynamic>{
        'uid': user.uid,
        'displayName': user.displayName ?? enteredName,
        'name': user.displayName ?? enteredName,
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await reference.set(data, SetOptions(merge: true));
    } catch (error) {
      Logger.error('Error saving email user data: $error');
    }
  }

  String? _validateName(String? value) {
    if (_isLoginMode) return null;
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter your full name';
    if (name.length < 2) return 'Please enter a valid name';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email address';
    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!validEmail.hasMatch(email)) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter your password';
    if (!_isLoginMode && password.length < 6) {
      return 'Password must contain at least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      late final UserCredential credential;
      if (_isLoginMode) {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user?.updateDisplayName(_nameController.text.trim());
        await credential.user?.reload();
      }

      final user = _auth.currentUser ?? credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Authentication completed without a user account.',
        );
      }

      await _saveUserData(user);
      if (!mounted || _hasNavigated) return;

      _showMessage(
        _isLoginMode ? 'Welcome back!' : 'Your account has been created.',
      );
      _hasNavigated = true;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on FirebaseAuthException catch (error) {
      Logger.error('Email authentication error: ${error.code}');
      if (mounted) _showMessage(_friendlyAuthError(error), isError: true);
    } catch (error) {
      Logger.error('Unexpected email authentication error: $error');
      if (mounted) {
        _showMessage('Something went wrong. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this app.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetController = TextEditingController(text: _emailController.text.trim());
    bool sending = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !sending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.lock_reset_rounded, color: _green, size: 32),
              title: const Text('Reset password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email and we will send you a password reset link.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: resetController,
                    enabled: !sending,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(
                      label: 'Email address',
                      icon: Icons.mail_outline_rounded,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = resetController.text.trim();
                          if (_validateEmail(email) != null) {
                            _showMessage(
                              'Please enter a valid email address.',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() => sending = true);
                          try {
                            await _auth.sendPasswordResetEmail(email: email);
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (mounted) {
                              _showMessage('Password reset email sent. Check your inbox.');
                            }
                          } on FirebaseAuthException catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() => sending = false);
                            }
                            if (mounted) {
                              _showMessage(_friendlyAuthError(error), isError: true);
                            }
                          }
                        },
                  child: sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send link'),
                ),
              ],
            );
          },
        );
      },
    );

    resetController.dispose();
  }

  void _toggleMode() {
    if (_isLoading) return;
    setState(() {
      _isLoginMode = !_isLoginMode;
      _passwordController.clear();
      _obscurePassword = true;
    });
    _formKey.currentState?.reset();
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _green),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE8DD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE8DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _green, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkGreen,
        elevation: 0,
        title: Text(_isLoginMode ? 'Email sign in' : 'Create account'),
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 20),
                      Text(
                        _isLoginMode ? 'Welcome back!' : 'Join Jarvis Green',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _darkGreen,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _isLoginMode
                            ? 'Sign in to continue your greener journey.'
                            : 'Create an account and start growing with us.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9EEDC), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A18864B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          AppAssets.logo,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFF0F8F1),
            alignment: Alignment.center,
            child: const Icon(Icons.eco_rounded, color: _green, size: 72),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
          if (!_isLoginMode) ...[
            TextFormField(
              controller: _nameController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: _validateName,
              decoration: _inputDecoration(
                label: 'Full name',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            validator: _validateEmail,
            decoration: _inputDecoration(
              label: 'Email address',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: _isLoginMode
                ? const [AutofillHints.password]
                : const [AutofillHints.newPassword],
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submit(),
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: _isLoading
                    ? null
                    : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _secondaryText,
                ),
              ),
            ),
          ),
          if (_isLoginMode)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                child: const Text('Forgot password?'),
              ),
            )
          else
            const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _green.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isLoginMode ? 'Sign in' : 'Create account',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _isLoginMode
                    ? "Don't have an account?"
                    : 'Already have an account?',
                style: const TextStyle(color: _secondaryText, fontSize: 13),
              ),
              TextButton(
                onPressed: _isLoading ? null : _toggleMode,
                child: Text(_isLoginMode ? 'Sign up' : 'Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
