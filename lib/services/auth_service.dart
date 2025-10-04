import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class FirebaseServices {
  FirebaseServices({
    GoogleSignIn? googleSignIn,
    FirebaseAuth? auth,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _auth = auth ?? FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _auth;

  /// Google Sign-In → Firebase
  Future<UserCredential?> loginUsingGoogle() async {
    try {
      // Start Google flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('[Auth] Google sign-in cancelled by user.');
        return null; // user cancelled
      }

      // Fetch tokens
      final GoogleSignInAuthentication tokens = await account.authentication;

      // This is the #1 cause of "null credential" on Android
      if (tokens.idToken == null) {
        debugPrint(
          '[Auth] idToken is NULL. '
              'Likely missing SHA-1/SHA-256 in Firebase → Android app or wrong google-services.json. '
              'Add SHA keys via `./gradlew signingReport`, update them in Firebase console, '
              're-download google-services.json, then flutter clean & rebuild.',
        );
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      if (userCred.user == null) {
        debugPrint('[Auth] Firebase returned null user after signInWithCredential.');
        return null;
      }

      debugPrint('[Auth] Google sign-in success: ${userCred.user!.uid}');
      return userCred;
    } on FirebaseAuthException catch (e, st) {
      // Handle common cases explicitly so you know what to fix
      debugPrint('[FirebaseAuthException] code=${e.code} message=${e.message}\n$st');

      if (e.code == 'invalid-credential') {
        debugPrint('[Auth] Invalid credential—often stale tokens. Try signOut() then retry.');
      } else if (e.code == 'operation-not-allowed') {
        debugPrint('[Auth] Google provider is disabled. Enable it in Firebase console.');
      } else if (e.code == 'network-request-failed') {
        debugPrint('[Auth] Network error—check connectivity/Play Services.');
      }
      return null;
    } catch (e, st) {
      debugPrint('[Auth] Unexpected error: $e\n$st');
      return null;
    }
  }

  /// Email/Password sign-up
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[Auth] Registered: ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signUp error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[Auth] signUp unexpected: $e');
      return null;
    }
  }

  /// Email/Password sign-in
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[Auth] Logged in: ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signIn error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[Auth] signIn unexpected: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Google + Firebase to avoid stale sessions
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    debugPrint('[Auth] Signed out');
  }

  /// Optional helper to quickly sanity-check environment at runtime.
  void debugEnvironmentHints() {
    debugPrint('[Env] Platform: ${Platform.operatingSystem}');
    debugPrint('[Env] Current user: ${_auth.currentUser?.uid}');
  }
}
