import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:relapse_flutter/models/app_user.dart';

/// Abstract auth service interface.
abstract class AuthService {
  Stream<AppUser?> get currentUser;
  AppUser? get currentUserSync;
  bool get isSignedIn;
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(
      String email, String password, String displayName);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
}

/// Firebase implementation of [AuthService].
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AppUser?> get currentUser {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _mapFirebaseUser(user);
    });
  }

  @override
  AppUser? get currentUserSync {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Sign in failed: no user returned');
    return _mapFirebaseUser(user);
  }

  @override
  Future<AppUser> signUpWithEmail(
      String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Sign up failed: no user returned');

    await user.updateDisplayName(displayName.trim());
    await user.reload();

    final appUser = AppUser(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
    );

    // Save profile to Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(appUser.toJson(), SetOptions(merge: true));

    return appUser;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    // Delete Firestore profile
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  AppUser _mapFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}
