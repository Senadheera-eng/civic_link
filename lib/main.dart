// main.dart (FIXED VERSION)
import 'package:civic_link/screens/setting_screen.dart';
import 'package:civic_link/screens/department_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard.dart';
import 'services/auth_service.dart';
import 'theme/simple_theme.dart';
import 'theme/modern_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:civic_link/services/notification_service.dart';
import 'models/user_model.dart';
import 'services/settings_service.dart';
import 'screens/report_issue_screen.dart';
import 'package:civic_link/screens/official_settings_screen.dart';

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

      // Localization support - temporarily disabled
      localizationsDelegates: const [
        // AppLocalizations.delegate, // Comment out until localization is fixed
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
        '/department': (context) => DepartmentDashboard(),
        '/settings': (context) => SettingsScreen(),
        '/official-settings': (context) => OfficialSettingsScreen(),
        '/report-issue': (context) => ModernReportIssueScreen(),
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
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        print("🔄 AuthWrapper: Connection state = ${snapshot.connectionState}");
        print("🔄 AuthWrapper: Has data = ${snapshot.hasData}");
        print("🔄 AuthWrapper: Data = ${snapshot.data?.email ?? 'null'}");

        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("⏳ AuthWrapper: Waiting for auth state...");
          return _buildLoadingScreen();
        }

        // Handle connection errors
        if (snapshot.hasError) {
          print("❌ AuthWrapper: Stream error: ${snapshot.error}");
          return _buildErrorScreen('Authentication error: ${snapshot.error}');
        }

        // Check if user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          print("✅ AuthWrapper: User authenticated, loading user data...");
          return _buildUserDataLoader(snapshot.data!);
        }

        // No authenticated user
        print("🔐 AuthWrapper: No authenticated user, showing login");
        return LoginScreen();
      },
    );
  }

  Widget _buildUserDataLoader(User user) {
    return FutureBuilder<UserModel?>(
      future: AuthService().getUserData(),
      builder: (context, userSnapshot) {
        print(
          "👤 AuthWrapper: User data state = ${userSnapshot.connectionState}",
        );

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          print("⏳ AuthWrapper: Loading user data...");
          return _buildLoadingScreen();
        }

        if (userSnapshot.hasError) {
          print("❌ AuthWrapper: User data error: ${userSnapshot.error}");
          return _buildErrorScreen(
            'Failed to load user profile: ${userSnapshot.error}',
          );
        }

        if (userSnapshot.hasData && userSnapshot.data != null) {
          return _buildUserInterface(userSnapshot.data!);
        }

        // No user data found - profile setup needed
        print("⚠️ AuthWrapper: No user data found for ${user.email}");
        return _buildProfileSetupScreen(user);
      },
    );
  }

  Widget _buildUserInterface(UserModel userData) {
    print("🔍 AuthWrapper: Routing user interface...");
    print("   - User Type: '${userData.userType}'");
    print("   - Department: '${userData.department ?? 'null'}'");
    print("   - Is Verified: ${userData.isVerified}");
    print("   - Is Active: ${userData.isActive}");

    final cleanUserType = userData.userType.trim().toLowerCase();
    print("🧹 Cleaned user type: '$cleanUserType'");

    switch (cleanUserType) {
      case 'official':
        print("🏛️ OFFICIAL USER ROUTING");

        if (userData.department == null ||
            userData.department!.trim().isEmpty) {
          print("❌ Official missing department");
          return _buildErrorScreen(
            "No department assigned to your account. Please contact administrator.",
          );
        }

        if (!userData.isActive) {
          print("❌ Official account inactive");
          return _buildErrorScreen(
            "Your account is inactive. Please contact administrator.",
          );
        }

        print("✅ ROUTING TO DEPARTMENT DASHBOARD");
        print("🏢 Department: ${userData.department}");
        return DepartmentDashboard();

      case 'citizen':
        print("👤 CITIZEN USER → Home Screen");
        return HomeScreen();

      default:
        print("❓ UNKNOWN USER TYPE: '$cleanUserType' → Defaulting to Home");
        return HomeScreen();
    }
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

  Widget _buildErrorScreen(String message) {
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
                    Icons.error_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Access Error',
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
                  message,
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
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
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
                  onPressed: () {
                    // Refresh the auth state
                    setState(() {});
                  },
                  child: const Text(
                    'Try Again',
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

  Widget _buildProfileSetupScreen(User user) {
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
