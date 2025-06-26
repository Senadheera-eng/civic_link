// main.dart (FIXED WITH PROPER USER ROLE ROUTING)
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

        // Simple loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserData(),
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

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final userData = userSnapshot.data!;
                print("🏷️ AuthWrapper: User type = ${userData.userType}");
                print("🏢 AuthWrapper: Department = ${userData.department}");
                print("✅ AuthWrapper: Is verified = ${userData.isVerified}");

                // SIMPLIFIED ROUTING - Only 2 user types
                if (userData.userType == 'official') {
                  if (!userData.isVerified) {
                    print(
                      "⚠️ AuthWrapper: Official account not verified - showing pending screen",
                    );
                    return _buildPendingVerificationScreen(userData, context);
                  } else {
                    print("➡️ AuthWrapper: Routing to Department Dashboard");
                    return DepartmentDashboard();
                  }
                } else {
                  // All other users go to citizen home (including 'citizen' type)
                  print("➡️ AuthWrapper: Routing to Citizen Home Screen");
                  return HomeScreen();
                }
              }

              print(
                "⚠️ AuthWrapper: No user data found, defaulting to Home Screen",
              );
              return HomeScreen();
            },
          );
        }

        // User not logged in - show login
        print("🔐 AuthWrapper: No authenticated user, routing to Login");
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
              // Simple animated logo
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
                'Report. Track. Resolve.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingVerificationScreen(
    UserModel userData,
    BuildContext context,
  ) {
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
                // Pending verification icon
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
                    Icons.pending,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Account Pending Verification',
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
                  'Welcome ${userData.fullName}!',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your ${userData.department} official account is currently under review.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Employee ID: ${userData.employeeId}\nDepartment: ${userData.department}\n\nYou will be notified once your account is verified by the administrator.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: () async {
                            await AuthService().signOut();
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            // Refresh the auth state to check if verification status changed
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          icon: Icon(
                            Icons.refresh,
                            color: SimpleTheme.primaryBlue,
                          ),
                          label: Text(
                            'Refresh',
                            style: TextStyle(
                              color: SimpleTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Need help? Contact support at support@civiclink.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
