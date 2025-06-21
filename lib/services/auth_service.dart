import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String fullName,
    String userType,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(result.user!, fullName, userType);

      return result;
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Check if user document exists, create if not
      await _createUserDocument(
        result.user!,
        googleUser.displayName ?? '',
        'citizen',
      );

      return result;
    } catch (e) {
      throw 'Google sign-in failed. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user,
    String fullName,
    String userType,
  ) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fullName': fullName,
        'userType': userType, // 'citizen' or 'admin'
        'createdAt': FieldValue.serverTimestamp(),
        'profilePicture': user.photoURL ?? '',
      });
    }
  }

  // Get user data
  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Error message helper
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Invalid password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
