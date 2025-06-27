// main.dart (FIXED AuthWrapper with better debugging)
import 'package:civic_link/screens/setting_screen.dart';
import 'package:civic_link/screens/department_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'services/auth_service.dart';
import 'theme/simple_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:civic_link/services/notification_service.dart';
import 'models/user_model.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase FIRST with timeout
    print("🔥 Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(Duration(seconds: 30));
    print("✅ Firebase initialized successfully");

    // Test Firebase connection
    try {
      print("🧪 Testing Firebase connectivity...");
      await FirebaseFirestore.instance.enableNetwork().timeout(
        Duration(seconds: 10),
      );
      print("✅ Firebase Firestore network enabled");
    } catch (e) {
      print("⚠️ Firebase network test failed: $e");
    }

    // Initialize Notifications AFTER Firebase
    print("🔔 Initializing Notifications...");
    try {
      await NotificationService().initialize().timeout(Duration(seconds: 15));
      print("✅ Notifications initialized successfully");
    } catch (e) {
      print("⚠️ Notification initialization failed: $e");
    }

    // Initialize Settings
    try {
      await SettingsService().initializeSettings().timeout(
        Duration(seconds: 10),
      );
      print("✅ Settings service initialized");
    } catch (e) {
      print("⚠️ Settings initialization failed: $e");
    }
  } catch (e) {
    print("❌ Initialization failed: $e");
    // Continue anyway - the app can still work with limited functionality
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicLink',
      debugShowCheckedModeBanner: false,
      theme: SimpleTheme.lightTheme,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/admin': (context) => AdminDashboard(),
        '/department': (context) => DepartmentDashboard(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        print("🔄 AuthWrapper: Connection state = ${snapshot.connectionState}");
        print("🔄 AuthWrapper: Has data = ${snapshot.hasData}");
        print("🔄 AuthWrapper: Data = ${snapshot.data?.email ?? 'null'}");

        // Loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserData(forceRefresh: true),
            builder: (context, userSnapshot) {
              print(
                "👤 AuthWrapper: User data connection state = ${userSnapshot.connectionState}",
              );
              print(
                "👤 AuthWrapper: User data = ${userSnapshot.data?.toString() ?? 'null'}",
              );

              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (userSnapshot.hasError) {
                print(
                  "❌ AuthWrapper: Error loading user data: ${userSnapshot.error}",
                );
                return _buildErrorScreen(userSnapshot.error.toString());
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final userData = userSnapshot.data!;
                print("🔍 AuthWrapper: USER ROUTING ANALYSIS:");
                print("   - User Type: '${userData.userType}'");
                print("   - Department: '${userData.department ?? 'null'}'");
                print("   - Is Verified: ${userData.isVerified}");
                print("   - Is Active: ${userData.isActive}");

                // Clean user type for comparison
                final cleanUserType = userData.userType.trim().toLowerCase();
                print("🧹 Cleaned user type: '$cleanUserType'");

                // SIMPLIFIED ROUTING LOGIC
                switch (cleanUserType) {
                  case 'official':
                    print("🏛️ OFFICIAL USER DETECTED");

                    // Check if user has department
                    if (userData.department == null ||
                        userData.department!.trim().isEmpty) {
                      print("❌ Official missing department");
                      return _buildErrorScreen(
                        "No department assigned. Please contact administrator.",
                      );
                    }

                    // Check if account is active
                    if (!userData.isActive) {
                      print("❌ Official account inactive");
                      return _buildErrorScreen(
                        "Account is inactive. Please contact administrator.",
                      );
                    }

                    print("✅ ROUTING TO DEPARTMENT DASHBOARD");
                    print("🏢 Department: ${userData.department}");
                    return DepartmentDashboard();

                  case 'citizen':
                    print("👤 CITIZEN USER → Home Screen");
                    return HomeScreen();

                  case 'admin':
                    print("🔧 ADMIN USER → Admin Dashboard");
                    return AdminDashboard();

                  default:
                    print("❓ UNKNOWN USER TYPE: '$cleanUserType'");
                    print("🔄 Defaulting to Home Screen");
                    return HomeScreen();
                }
              }

              // No user data found
              print("⚠️ AuthWrapper: No user data found");
              final currentUser = snapshot.data;
              if (currentUser != null) {
                print("🔧 No user document for: ${currentUser.email}");
                return _buildProfileSetupScreen(currentUser, context);
              }

              return HomeScreen();
            },
          );
        }

        // User not logged in
        print("🔐 AuthWrapper: No authenticated user → Login");
        return LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SimpleTheme.primaryBlue, SimpleTheme.primaryDark],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_city, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'CivicLink',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Loading your dashboard...',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade400, Colors.red.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Account Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out & Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSetupScreen(User user, BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SimpleTheme.primaryBlue, SimpleTheme.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Profile Setup Required',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome ${user.email}!\nComplete your registration to continue.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Complete Registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: SimpleTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
