// services/auth_service.dart (ENHANCED WITH DEPARTMENT SUPPORT)
import 'package:civic_link/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges {
    print("🔄 AuthService: Creating auth state stream");
    return _auth.authStateChanges();
  }

  User? get currentUser {
    final user = _auth.currentUser;
    print("👤 AuthService: Current user = ${user?.email ?? 'null'}");
    return user;
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      print("🔐 AuthService: Starting sign in process");
      print("📧 Email: $email");
      print("🔒 Password length: ${password.length}");

      // Check current auth state
      print(
        "🔍 Current auth state before sign in: ${_auth.currentUser?.email ?? 'null'}",
      );

      // Attempt sign in
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print("✅ Firebase sign in successful!");
      print("👤 Signed in user: ${result.user?.email}");
      print("🆔 User UID: ${result.user?.uid}");
      print("✉️ Email verified: ${result.user?.emailVerified}");

      return result;
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException occurred:");
      print("   Code: ${e.code}");
      print("   Message: ${e.message}");
      print("   Details: $e");

      // Handle specific error codes
      switch (e.code) {
        case 'user-not-found':
          throw 'No account found with this email address.';
        case 'wrong-password':
          throw 'Incorrect password. Please try again.';
        case 'invalid-email':
          throw 'Please enter a valid email address.';
        case 'user-disabled':
          throw 'This account has been disabled.';
        case 'too-many-requests':
          throw 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          throw 'Network error. Please check your internet connection.';
        case 'invalid-credential':
          throw 'Invalid email or password. Please check your credentials.';
        default:
          throw 'Login failed: ${e.message ?? 'Unknown error'}';
      }
    } catch (e) {
      print("❌ General error during sign in: $e");
      throw 'Login failed: ${e.toString()}';
    }
  }

  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String fullName,
    String userType, {
    String? department,
    String? employeeId,
  }) async {
    try {
      print("🔐 AuthService: Starting registration process");
      print("📧 Email: $email");
      print("👤 Full name: $fullName");
      print("🏷️ User type: $userType");
      if (department != null) print("🏢 Department: $department");
      if (employeeId != null) print("🆔 Employee ID: $employeeId");

      // Validate official account requirements
      if (userType == 'official') {
        if (department == null || department.isEmpty) {
          throw 'Department is required for official accounts';
        }
        if (employeeId == null || employeeId.isEmpty) {
          throw 'Employee ID is required for official accounts';
        }

        // Check if employee ID already exists
        final existingEmployee =
            await _firestore
                .collection('users')
                .where('employeeId', isEqualTo: employeeId)
                .where('userType', isEqualTo: 'official')
                .get();

        if (existingEmployee.docs.isNotEmpty) {
          throw 'This Employee ID is already registered';
        }
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print("✅ Firebase registration successful!");
      print("👤 New user: ${result.user?.email}");
      print("🆔 User UID: ${result.user?.uid}");

      // Create user document in Firestore
      await _createUserDocument(
        result.user!,
        fullName,
        userType,
        department: department,
        employeeId: employeeId,
      );

      // Send welcome notification
      await NotificationService().sendWelcomeNotification(result.user!.uid);

      // Send department-specific welcome for officials
      if (userType == 'official' && department != null) {
        await _sendDepartmentWelcomeNotification(result.user!.uid, department);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print("❌ Registration FirebaseAuthException:");
      print("   Code: ${e.code}");
      print("   Message: ${e.message}");

      switch (e.code) {
        case 'weak-password':
          throw 'Password is too weak. Please choose a stronger password.';
        case 'email-already-in-use':
          throw 'An account already exists with this email address.';
        case 'invalid-email':
          throw 'Please enter a valid email address.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled.';
        default:
          throw 'Registration failed: ${e.message ?? 'Unknown error'}';
      }
    } catch (e) {
      print("❌ General registration error: $e");
      throw 'Registration failed: ${e.toString()}';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      print("🔐 AuthService: Starting Google sign in");

      // Clear any existing Google sign-in state
      await _googleSignIn.signOut();
      print("🧹 Cleared existing Google sign-in state");

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("❌ Google sign in cancelled by user");
        throw 'Google sign-in was cancelled';
      }

      print("👤 Google user: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      print("✅ Google sign in successful!");
      print("👤 Signed in user: ${result.user?.email}");

      // Check if user document exists, create if not
      await _createUserDocument(
        result.user!,
        googleUser.displayName ?? 'Google User',
        'citizen', // Google users default to citizen
      );

      return result;
    } catch (e) {
      print("❌ Google sign in error: $e");
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    try {
      print("🔐 AuthService: Starting sign out process");
      print(
        "👤 Current user before sign out: ${_auth.currentUser?.email ?? 'null'}",
      );

      // Sign out from Google first
      try {
        await _googleSignIn.signOut();
        print("✅ Google sign out successful");
      } catch (e) {
        print("⚠️ Google sign out error (may be normal): $e");
      }

      // Sign out from Firebase
      await _auth.signOut();
      print("✅ Firebase sign out successful");

      // Verify sign out
      print(
        "👤 Current user after sign out: ${_auth.currentUser?.email ?? 'null'}",
      );
    } catch (e) {
      print("❌ Sign out error: $e");
      throw 'Sign out failed: ${e.toString()}';
    }
  }

  Future<UserModel?> getUserData() async {
    final user = currentUser;
    print("📋 AuthService: Getting user data for ${user?.email ?? 'null'}");

    if (user == null) {
      print("❌ No current user found");
      return null;
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        print("✅ User document found in Firestore");
        final userData = UserModel.fromFirestore(doc);
        print("👤 User data: ${userData.fullName} (${userData.userType})");
        if (userData.department != null)
          print("🏢 Department: ${userData.department}");
        return userData;
      } else {
        print("⚠️ User document not found in Firestore, creating default");
        // Return default user model if Firestore doc doesn't exist
        final defaultUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? 'User',
          userType: 'citizen',
        );

        // Try to create the document
        try {
          await _createUserDocument(
            user,
            defaultUser.fullName,
            defaultUser.userType,
          );
        } catch (e) {
          print("⚠️ Failed to create user document: $e");
        }

        return defaultUser;
      }
    } catch (e) {
      print("❌ Error getting user data: $e");
      return null;
    }
  }

  Future<void> _createUserDocument(
    User user,
    String fullName,
    String userType, {
    String? department,
    String? employeeId,
  }) async {
    try {
      print("📄 Creating user document for ${user.email}");

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'fullName': fullName,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
          'profilePicture': user.photoURL ?? '',
          'isVerified': false,
          'isActive': true,
        };

        // Add department-specific fields for officials
        if (userType == 'official') {
          userData['department'] = department;
          userData['employeeId'] = employeeId;
          userData['isVerified'] = false; // Officials need verification
        }

        await _firestore.collection('users').doc(user.uid).set(userData);
        print("✅ User document created successfully");

        // Log official registration for admin review
        if (userType == 'official') {
          await _logOfficialRegistration(
            user.uid,
            fullName,
            department!,
            employeeId!,
          );
        }
      } else {
        print("ℹ️ User document already exists");
      }
    } catch (e) {
      print("❌ Error creating user document: $e");
      // Don't throw here - login can succeed even if Firestore fails
    }
  }

  Future<void> _logOfficialRegistration(
    String userId,
    String fullName,
    String department,
    String employeeId,
  ) async {
    try {
      await _firestore.collection('admin_logs').add({
        'type': 'official_registration',
        'userId': userId,
        'fullName': fullName,
        'department': department,
        'employeeId': employeeId,
        'status': 'pending_verification',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Official registration logged for admin review");
    } catch (e) {
      print("❌ Error logging official registration: $e");
    }
  }

  Future<void> _sendDepartmentWelcomeNotification(
    String userId,
    String department,
  ) async {
    try {
      await NotificationService().sendNotificationToUser(
        userId: userId,
        title: '🏢 Welcome to $department!',
        body:
            'You can now manage issues related to $department. Please wait for account verification.',
        data: {'type': 'department_welcome', 'department': department},
      );
    } catch (e) {
      print("❌ Error sending department welcome notification: $e");
    }
  }

  // Get users by department (for admins)
  Future<List<UserModel>> getUsersByDepartment(String department) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('department', isEqualTo: department)
              .where('userType', isEqualTo: 'official')
              .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("❌ Error getting users by department: $e");
      return [];
    }
  }

  // Verify official account (admin function)
  Future<void> verifyOfficialAccount(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to the official
      if (isVerified) {
        await NotificationService().sendNotificationToUser(
          userId: userId,
          title: '✅ Account Verified!',
          body:
              'Your official account has been verified. You can now fully access department features.',
          data: {'type': 'account_verified'},
        );
      }

      print("✅ Official account verification updated");
    } catch (e) {
      print("❌ Error verifying official account: $e");
      throw 'Failed to verify account: $e';
    }
  }

  // Get pending official registrations (admin function)
  Stream<List<Map<String, dynamic>>> getPendingOfficialRegistrations() {
    return _firestore
        .collection('admin_logs')
        .where('type', isEqualTo: 'official_registration')
        .where('status', isEqualTo: 'pending_verification')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .toList(),
        );
  }

  // Update user department (admin function)
  Future<void> updateUserDepartment(String userId, String newDepartment) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'department': newDepartment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ User department updated");
    } catch (e) {
      print("❌ Error updating user department: $e");
      throw 'Failed to update department: $e';
    }
  }

  // Check current auth state
  Future<void> checkAuthState() async {
    print("🔍 AuthService: Checking current auth state");
    final user = _auth.currentUser;
    if (user != null) {
      print("👤 User is signed in: ${user.email}");
      print("🆔 UID: ${user.uid}");
      print("✉️ Email verified: ${user.emailVerified}");
      print("🕒 Last sign in: ${user.metadata.lastSignInTime}");
    } else {
      print("❌ No user is currently signed in");
    }
  }

  // Refresh auth state
  Future<void> refreshAuth() async {
    try {
      print("🔄 AuthService: Refreshing auth state");
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        print("✅ Auth state refreshed");
      }
    } catch (e) {
      print("❌ Error refreshing auth: $e");
    }
  }
}
