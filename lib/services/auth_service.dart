import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _googleInitialized = false;

  Stream<User?> get userStream =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user != null) await ensureUserProfile(user);
        return user;
      });

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Account creation returned no user.');
    await user.updateDisplayName(name.trim());
    await ensureUserProfile(user, displayName: name.trim());
  }

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) await ensureUserProfile(user);
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      final user = credential.user;
      if (user != null) await ensureUserProfile(user);
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError(
        'Google sign-in is set up for Android, iOS, and web.',
      );
    }

    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? DefaultFirebaseOptions.ios.iosClientId
            : null,
      );
      _googleInitialized = true;
    }

    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google did not return an ID token. Check OAuth setup.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) await ensureUserProfile(user);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
      _googleInitialized = false;
    }
  }

  Future<void> ensureUserProfile(User user, {String? displayName}) async {
    final profile = _firestore.collection('users').doc(user.uid);
    final existing = await profile.get();
    final name = displayName ?? user.displayName;
    final data = <String, Object?>{
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null && name.isNotEmpty) data['displayName'] = name;
    if (user.photoURL != null) data['photoUrl'] = user.photoURL;
    if (!existing.exists) {
      data.addAll({
        'createdAt': FieldValue.serverTimestamp(),
        'preferredLanguage': 'fr',
        'themeMode': 'system',
      });
    }
    await profile.set(data, SetOptions(merge: true));
  }
}

String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a little and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
    }
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Firebase denied this request. Check the Firestore security rules.';
  }
  if (error is UnsupportedError) {
    return error.message ?? 'This feature is unavailable.';
  }
  if (error is StateError) return error.message;
  return 'Something went wrong. Please try again.';
}
