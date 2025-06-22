import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase already initialized: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicLink',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginScreen(),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen(); // User is logged in
        }

        return LoginScreen(); // User is not logged in
      },
    );
  }
}
