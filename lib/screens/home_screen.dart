import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicLink'),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') _signOut();
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${_userData?.fullName ?? 'User'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'User Type: ${_userData?.userType ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Feature Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.report_problem,
                    title: 'Report Issue',
                    subtitle: 'Report community problems',
                    onTap: () {
                      // Navigate to report screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report Issue feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.track_changes,
                    title: 'Track Issues',
                    subtitle: 'View your reported issues',
                    onTap: () {
                      // Navigate to tracking screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Issue tracking feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.map,
                    title: 'Issue Map',
                    subtitle: 'View issues on map',
                    onTap: () {
                      // Navigate to map screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Map feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'View updates',
                    onTap: () {
                      // Navigate to notifications screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications feature coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
