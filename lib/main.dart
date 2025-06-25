// main.dart (FIXED VERSION WITH PROPER ERROR HANDLING)
import 'package:civic_link/services/notification_service.dart';
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
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase FIRST
    print("🔥 Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");

    // Initialize Notifications AFTER Firebase
    print("🔔 Initializing Notifications...");
    await NotificationService().initialize();
    print("✅ Notifications initialized successfully");
  } catch (e) {
    print("❌ Initialization failed: $e");
    // Continue anyway - app can work without notifications
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
        // Simple loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final userData = userSnapshot.data!;
                if (userData.isAdmin) {
                  return AdminDashboard();
                } else {
                  return HomeScreen();
                }
              }

              return HomeScreen();
            },
          );
        }

        // User not logged in - show login
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
}
