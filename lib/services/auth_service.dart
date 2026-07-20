// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plantmitra_1/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    forceCodeForRefreshToken: true,
    signInOption: SignInOption.standard,
  );

  // --- 1. Check if user is already logged in ---
  Future<bool> isUserLoggedIn() async {
    // Firebase check
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      Logger.debug("✅ User already logged in via Firebase: ${currentUser.email}");
      return true;
    }

    // Google Sign-In silent check
    // This works when user is already logged in and session is active
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        Logger.debug("✅ Google account found silently: ${account.email}");
        return true;
      }
    } catch (e) {
      Logger.warning("Silent sign-in failed: $e");
    }

    Logger.debug("❌ No active session found.");
    return false;
  }

  // --- 2. Login Function (Explicit) ---
  Future<User?> signInWithGoogle() async {
    try {
      Logger.debug("Google Sign-In started");

      // Sign out from previous sessions to ensure clean login
      await _googleSignIn.signOut();
      await _auth.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      Logger.debug("Selected account: $account");

      if (account == null) {
        Logger.debug("User cancelled login");
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      Logger.info("Login Success: ${userCredential.user?.email}");

      return userCredential.user;
    } catch (e, s) {
      Logger.error("Google Login Error: $e", error: s);
      return null;
    }
  }

  // --- 3. Logout Function ---
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      Logger.info("👋 Logged out successfully");
    } catch (e) {
      Logger.error("❌ Logout Error: $e");
      rethrow; // Optionally rethrow to let caller handle it
    }
  }

  // --- 4. Get Current User ---
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // --- 5. Get User ID ---
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // --- 6. Check if user is authenticated ---
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // --- 7. Get User Stream ---
  Stream<User?> getUserStream() {
    return _auth.authStateChanges();
  }
}