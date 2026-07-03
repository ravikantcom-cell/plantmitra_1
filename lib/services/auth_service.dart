import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
  forceCodeForRefreshToken: true,
  signInOption: SignInOption.standard,
);

  // --- 1. Check karein ki user already login hai ya nahi ---
  Future<bool> isUserLoggedIn() async {
    // Firebase se check
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      print("✅ User already logged in via Firebase: ${currentUser.email}");
      return true;
    }

    // Google Sign-In se silent check
    // Ye tab kaam karta hai jab user pehle se login hai aur session active hai
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    if (account != null) {
      print("✅ Google account found silently: ${account.email}");
      return true;
    }

    print("❌ No active session found.");
    return false;
  }

  // --- 2. Login Function (Explicit) ---
  Future<User?> signInWithGoogle() async {
  try {
    print("Google Sign-In started");

    await _googleSignIn.signOut();
    await _auth.signOut();

    final GoogleSignInAccount? account =
        await _googleSignIn.signIn();

    print("Selected account: $account");

    if (account == null) {
      print("User cancelled login");
      return null;
    }

    final GoogleSignInAuthentication auth =
        await account.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    print("Login Success: ${userCredential.user?.email}");

    return userCredential.user;
  } catch (e, s) {
    print("Google Login Error: $e");
    print(s);
    return null;
  }
}

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print("👋 Logged out successfully");
    } catch (e) {
      print("❌ Logout Error: $e");
    }
  }
}