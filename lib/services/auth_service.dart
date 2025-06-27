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

      // Wait for Firebase to fully process the authentication
      await Future.delayed(Duration(milliseconds: 500));

      // Verify the user is actually signed in
      final currentUser = _auth.currentUser;
      print("🔍 Current user after sign in: ${currentUser?.email ?? 'null'}");

      if (currentUser == null) {
        throw Exception(
          'Sign in failed - no current user after authentication',
        );
      }

      // Force refresh the auth state
      await currentUser.reload();
      print("🔄 User reloaded successfully");

      // Test Firestore access
      try {
        print("📊 Testing Firestore access...");
        final userData = await _getUserDataFresh(currentUser.uid);
        print("📊 User data retrieved: ${userData?.toString() ?? 'null'}");

        if (userData == null) {
          print("⚠️ Warning: No user document found in Firestore");
        }
      } catch (e) {
        print("⚠️ Warning: Firestore access test failed: $e");
      }

      print("✅ Sign in process completed successfully");
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

  // Add this new method to get fresh user data without caching
  Future<UserModel?> _getUserDataFresh(String uid) async {
    try {
      print("📋 AuthService: Getting FRESH user data for UID: $uid");

      // Force network fetch from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: Source.server)) // Force server fetch
          .timeout(Duration(seconds: 15));

      if (doc.exists) {
        print("✅ Fresh user document found in Firestore");
        final userData = UserModel.fromFirestore(doc);
        print("👤 Fresh user data loaded:");
        print("   Name: ${userData.fullName}");
        print("   Type: ${userData.userType}");
        print("   Department: ${userData.department ?? 'N/A'}");
        print("   Verified: ${userData.isVerified}");
        print("   Email: ${userData.email}");

        return userData;
      } else {
        print("⚠️ Fresh user document not found in Firestore");
        return null;
      }
    } catch (e) {
      print("❌ Error getting fresh user data: $e");
      return null;
    }
  }

  Future<bool> testFirebaseConnection() async {
    try {
      print("🧪 Testing Firebase connection...");

      // Test Firestore connection
      await _firestore
          .collection('test')
          .doc('connection_test')
          .set({'timestamp': FieldValue.serverTimestamp()})
          .timeout(Duration(seconds: 10));

      print("✅ Firebase Firestore connection successful");

      // Clean up test document
      await _firestore.collection('test').doc('connection_test').delete();

      return true;
    } catch (e) {
      print("❌ Firebase connection test failed: $e");
      return false;
    }
  }

  Future<void> checkFirebaseStatus() async {
    final isConnected = await testFirebaseConnection();
    if (!isConnected) {
      // Show user-friendly error message
      print(
        "🌐 Firebase is not accessible. Please check your internet connection.",
      );
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
      print("🔐 DEBUG: AuthService registerWithEmail called");
      print("📧 DEBUG: Email: $email");
      print("👤 DEBUG: Full name: $fullName");
      print("🏷️ DEBUG: User type: $userType");
      if (department != null) print("🏢 DEBUG: Department: $department");
      if (employeeId != null) print("🆔 DEBUG: Employee ID: $employeeId");

      // Validate official account requirements
      if (userType == 'official') {
        if (department == null || department.isEmpty) {
          throw 'Department is required for official accounts';
        }
        if (employeeId == null || employeeId.isEmpty) {
          throw 'Employee ID is required for official accounts';
        }
        print("✅ DEBUG: Official account validation passed");
      }

      print("🔥 DEBUG: Creating Firebase user account...");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print("✅ DEBUG: Firebase registration successful!");
      print("👤 DEBUG: New user: ${result.user?.email}");
      print("🆔 DEBUG: User UID: ${result.user?.uid}");

      // Create user document in Firestore
      print("📄 DEBUG: About to call _createUserDocument...");
      await _createUserDocument(
        result.user!,
        fullName,
        userType,
        department: department,
        employeeId: employeeId,
      );

      print("✅ DEBUG: _createUserDocument completed");
      return result;
    } catch (e) {
      print("❌ DEBUG: registerWithEmail error: $e");
      rethrow;
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

  Future<void> _createUserDocument(
    User user,
    String fullName,
    String userType, {
    String? department,
    String? employeeId,
  }) async {
    try {
      print("📄 Creating user document for ${user.email}");
      print("🏷️ User type: $userType");
      print("🏢 Department: $department");
      print("🆔 Employee ID: $employeeId");

      // Create basic user data with detailed logging
      final userData = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': fullName,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'profilePicture': user.photoURL ?? '',
        'isActive': true,
      };

      // Add fields based on user type
      if (userType == 'official') {
        userData['department'] = department ?? '';
        userData['employeeId'] = employeeId ?? '';
        // AUTO-VERIFY OFFICIALS - No manual verification needed
        userData['isVerified'] = true;
        userData['verifiedAt'] = FieldValue.serverTimestamp();
        userData['verifiedBy'] = 'auto_verification_on_registration';

        print("🏢 Added official-specific fields:");
        print("   - department: ${userData['department']}");
        print("   - employeeId: ${userData['employeeId']}");
        print("   - isVerified: ${userData['isVerified']} (AUTO-VERIFIED)");
      } else {
        userData['isVerified'] = true;
        userData['verifiedAt'] = FieldValue.serverTimestamp();
        print("👤 Set as verified citizen");
      }

      print("💾 Complete user data to save:");
      userData.forEach((key, value) {
        print("   $key: $value");
      });

      print("💾 Attempting to save to Firestore...");

      // Try to write to Firestore with detailed error catching
      await _firestore.collection('users').doc(user.uid).set(userData);

      print("✅ User document created successfully in Firestore");

      // Verify the document was created
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        print("✅ Document verification successful");
        print("📄 Saved data: ${doc.data()}");
      } else {
        print("❌ Document verification failed - document doesn't exist");
      }
    } catch (e) {
      print("❌ Error creating user document: $e");
      print("❌ Error type: ${e.runtimeType}");

      // Check specific error types
      if (e.toString().contains('permission-denied')) {
        print("🚫 PERMISSION DENIED ERROR");
        print("🔧 Check your Firestore security rules");
        throw 'Permission denied: Please check Firestore security rules';
      } else if (e.toString().contains('unavailable')) {
        print("🌐 NETWORK/SERVICE UNAVAILABLE ERROR");
        throw 'Service unavailable: Please check your internet connection';
      } else {
        print("❓ UNKNOWN ERROR");
        throw 'Failed to create user profile: ${e.toString()}';
      }
    }
  }

  // ONE-TIME FIX: Update existing official accounts to verified
  Future<void> fixExistingOfficialAccounts() async {
    try {
      print("🔧 Fixing existing official accounts...");

      // Get all official accounts that are not verified
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('userType', isEqualTo: 'official')
              .where('isVerified', isEqualTo: false)
              .get();

      print(
        "📋 Found ${querySnapshot.docs.length} unverified official accounts",
      );

      final batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        print("🔧 Fixing account: ${data['email']} (${data['department']})");

        batch.update(doc.reference, {
          'isVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedBy': 'auto_fix_existing_officials',
        });
      }

      await batch.commit();
      print("✅ Fixed ${querySnapshot.docs.length} official accounts");
    } catch (e) {
      print("❌ Error fixing official accounts: $e");
      throw e;
    }
  }

  Future<UserCredential?> testRegistration(
    String email,
    String password,
    String fullName,
    String userType, {
    String? department,
    String? employeeId,
  }) async {
    try {
      print("🧪 STARTING TEST REGISTRATION");
      print("📧 Email: $email");
      print("🏷️ User type: $userType");

      // Step 1: Create Firebase Auth user
      print("\n🔥 Step 1: Creating Firebase Auth user...");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print("✅ Firebase Auth user created successfully");
      print("🆔 UID: ${result.user?.uid}");

      // Step 2: Test basic Firestore write
      print("\n📝 Step 2: Testing basic Firestore write...");
      await _firestore.collection('test').doc('write_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'basic write test',
      });
      print("✅ Basic Firestore write successful");

      // Step 3: Test user document creation
      print("\n👤 Step 3: Creating user document...");

      // Create minimal user document first
      final minimalData = {
        'uid': result.user!.uid,
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print("💾 Writing minimal user data: $minimalData");
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(minimalData);
      print("✅ Minimal user document created");

      // Step 4: Add additional fields if official
      if (userType == 'official') {
        print("\n🏢 Step 4: Adding official fields...");
        await _firestore.collection('users').doc(result.user!.uid).update({
          'fullName': fullName,
          'department': department,
          'employeeId': employeeId,
          'isVerified': false,
          'isActive': true,
        });
        print("✅ Official fields added successfully");
      } else {
        print("\n👤 Step 4: Adding citizen fields...");
        await _firestore.collection('users').doc(result.user!.uid).update({
          'fullName': fullName,
          'isVerified': true,
          'isActive': true,
        });
        print("✅ Citizen fields added successfully");
      }

      // Step 5: Verify final document
      print("\n🔍 Step 5: Verifying final document...");
      final finalDoc =
          await _firestore.collection('users').doc(result.user!.uid).get();

      if (finalDoc.exists) {
        print("✅ Final document verification successful");
        print("📄 Final data: ${finalDoc.data()}");
      }

      // Clean up test document
      await _firestore.collection('test').doc('write_test').delete();

      print("\n🎉 TEST REGISTRATION COMPLETED SUCCESSFULLY");
      return result;
    } catch (e) {
      print("\n❌ TEST REGISTRATION FAILED");
      print("❌ Error: $e");
      print("❌ Error type: ${e.runtimeType}");
      throw e;
    }
  }

  // Enhanced getUserData with retry mechanism
  Future<UserModel?> getUserData({bool forceRefresh = false}) async {
    final user = currentUser;
    print(
      "📋 AuthService: Getting user data for ${user?.email ?? 'null'} (forceRefresh: $forceRefresh)",
    );

    if (user == null) {
      print("❌ No current user found");
      return null;
    }

    try {
      // Add retry mechanism
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          // Force server fetch if requested or on first retry
          final source =
              (forceRefresh || retryCount > 0) ? Source.server : Source.cache;

          print(
            "📡 Fetching user data from: ${source == Source.server ? 'SERVER' : 'CACHE'}",
          );

          DocumentSnapshot doc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get(GetOptions(source: source))
              .timeout(Duration(seconds: 15));

          if (doc.exists) {
            print("✅ User document found in Firestore");
            final userData = UserModel.fromFirestore(doc);
            print("👤 User data loaded:");
            print("   Name: ${userData.fullName}");
            print(
              "   Type: '${userData.userType}' (length: ${userData.userType.length})",
            );
            print("   Department: '${userData.department ?? 'N/A'}'");
            print("   Verified: ${userData.isVerified}");
            print("   UID: ${userData.uid}");
            print("   Email: ${userData.email}");

            // Validate user type
            if (userData.userType.trim().isEmpty) {
              print("⚠️ WARNING: User type is empty, defaulting to 'citizen'");
              return userData.copyWith(userType: 'citizen');
            }

            return userData;
          } else {
            print("⚠️ User document not found in Firestore, creating default");
            // Return default user model if Firestore doc doesn't exist
            final defaultUser = UserModel(
              uid: user.uid,
              email: user.email ?? '',
              fullName: user.displayName ?? 'User',
              userType: 'citizen',
              isVerified: true,
            );

            return defaultUser;
          }
        } catch (e) {
          retryCount++;
          print("❌ Get user data attempt $retryCount failed: $e");

          if (retryCount >= maxRetries) {
            throw e;
          }

          await Future.delayed(Duration(seconds: retryCount * 2));
          print(
            "🔄 Retrying getUserData... (attempt ${retryCount + 1}/$maxRetries)",
          );
        }
      }
    } catch (e) {
      print("❌ Error getting user data after retries: $e");

      // Return a default user model for network errors
      if (e.toString().contains('unavailable') ||
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        print("🌐 Network error - returning default user");
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? 'User',
          userType: 'citizen',
          isVerified: true,
        );
      }

      return null;
    }

    return null;
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

  Future<void> debugUserData() async {
    try {
      final user = currentUser;
      if (user == null) {
        print("❌ DEBUG: No current user");
        return;
      }

      print("🔍 DEBUG: Starting user data analysis...");
      print("👤 Firebase Auth User:");
      print("   - UID: ${user.uid}");
      print("   - Email: ${user.email}");
      print("   - Display Name: ${user.displayName}");
      print("   - Email Verified: ${user.emailVerified}");

      // Check if user document exists in Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        print("❌ DEBUG: User document does NOT exist in Firestore");
        return;
      }

      print("✅ DEBUG: User document exists in Firestore");
      final data = doc.data() as Map<String, dynamic>;

      print("📄 DEBUG: Raw Firestore Data:");
      data.forEach((key, value) {
        print("   - $key: '$value' (${value.runtimeType})");
      });

      // Specifically check userType field
      final userType = data['userType'];
      print("🏷️ DEBUG: User Type Analysis:");
      print("   - Raw Value: '$userType'");
      print("   - Type: ${userType.runtimeType}");
      print("   - Length: ${userType?.toString().length ?? 0}");
      print("   - Trimmed: '${userType?.toString().trim()}'");
      print("   - Lowercase: '${userType?.toString().trim().toLowerCase()}'");

      // Check department info for officials
      if (userType?.toString().trim().toLowerCase() == 'official') {
        final department = data['department'];
        final employeeId = data['employeeId'];
        final isVerified = data['isVerified'];

        print("🏢 DEBUG: Official Account Analysis:");
        print("   - Department: '$department' (${department.runtimeType})");
        print("   - Employee ID: '$employeeId' (${employeeId.runtimeType})");
        print("   - Is Verified: '$isVerified' (${isVerified.runtimeType})");
        print(
          "   - Is Active: '${data['isActive']}' (${data['isActive'].runtimeType})",
        );
      }

      // Test UserModel creation
      try {
        final userModel = UserModel.fromFirestore(doc);
        print("✅ DEBUG: UserModel created successfully");
        print("👤 DEBUG: UserModel Properties:");
        print(
          "   - User Type: '${userModel.userType}' (${userModel.userType.runtimeType})",
        );
        print("   - Is Official: ${userModel.isOfficial}");
        print("   - Department: '${userModel.department ?? 'null'}'");
        print("   - Is Verified: ${userModel.isVerified}");
        print(
          "   - Can Access Dept Features: ${userModel.canAccessDepartmentFeatures}",
        );
      } catch (e) {
        print("❌ DEBUG: Error creating UserModel: $e");
      }
    } catch (e) {
      print("❌ DEBUG: Error in debugUserData: $e");
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
