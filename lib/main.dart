// main.dart (SIMPLE COLORFUL VERSION)
import 'package:civic_link/screens/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/setting_screen.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'theme/simple_theme.dart';
import 'theme/modern_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:civic_link/services/notification_service.dart';
import 'models/user_model.dart';
import 'services/settings_service.dart'; //for settings service

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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsService _settingsService = SettingsService();
  bool _isDarkMode = false;
  String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // Listen to settings changes
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _settingsService.initializeSettings();
    setState(() {
      _isDarkMode = _settingsService.isDarkMode;
      _currentLanguage = _settingsService.selectedLanguage;
    });
    print("🎨 App theme loaded: ${_isDarkMode ? 'Dark' : 'Light'}");
    print("🌍 App language loaded: $_currentLanguage");
  }

  void _onSettingsChanged() {
    setState(() {
      _isDarkMode = _settingsService.isDarkMode;
      _currentLanguage = _settingsService.selectedLanguage;
    });
    print(
      "🔄 Settings changed - Theme: ${_isDarkMode ? 'Dark' : 'Light'}, Language: $_currentLanguage",
    );
  }

  Locale _getLocale() {
    switch (_currentLanguage) {
      case 'Sinhala':
        return const Locale('si', 'LK');
      case 'English':
      default:
        return const Locale('en', 'US');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicLink',
      debugShowCheckedModeBanner: false,

      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('si', 'LK'), // Sinhala
      ],
      locale: _getLocale(),

      // Theme configuration
      theme: _isDarkMode ? _buildDarkTheme() : ModernTheme.lightTheme,
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

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

  // Enhanced dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: ModernTheme.primaryBlue,
        primaryContainer: Color(0xFF1A237E),
        secondary: ModernTheme.secondary,
        secondaryContainer: Color(0xFF4A148C),
        surface: Color(0xFF121212),
        surfaceVariant: Color(0xFF1E1E1E),
        background: Color(0xFF0A0A0A),
        error: ModernTheme.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: const Color(0xFF0A0A0A),

      appBarTheme: const AppBarTheme(
        backgroundColor: ModernTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ModernTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ModernTheme.primaryBlue,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF404040), width: 0.5),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return ModernTheme.primaryBlue;
          }
          return const Color(0xFF404040);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return ModernTheme.primaryBlue.withOpacity(0.5);
          }
          return const Color(0xFF2A2A2A);
        }),
      ),

      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white70,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white70),
      ),

      iconTheme: const IconThemeData(color: Colors.white70),
      primaryIconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Simple loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
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

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Container(
                    color: SimpleTheme.background,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                );
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
}

// Import for compatibility
