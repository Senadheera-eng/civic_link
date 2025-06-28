// widgets/department/department_header.dart
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/modern_theme.dart';

class DepartmentHeader extends StatelessWidget {
  final UserModel? userData;
  final int urgentCount;
  final bool isRefreshing;
  final Animation<double> refreshAnimation;
  final VoidCallback onSignOut;
  final VoidCallback onShowAnalytics;

  const DepartmentHeader({
    Key? key,
    required this.userData,
    required this.urgentCount,
    required this.isRefreshing,
    required this.refreshAnimation,
    required this.onSignOut,
    required this.onShowAnalytics,
  }) : super(key: key);

  IconData _getDepartmentIcon(String department) {
    final departmentInfo = Departments.getByName(department);
    switch (departmentInfo?['icon']) {
      case 'construction':
        return Icons.construction;
      case 'water_drop':
        return Icons.water_drop;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'security':
        return Icons.security;
      case 'delete':
        return Icons.delete;
      case 'park':
        return Icons.park;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'business':
        return Icons.business;
      case 'traffic':
        return Icons.traffic;
      case 'eco':
        return Icons.eco;
      default:
        return Icons.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentInfo = Departments.getByName(userData?.department ?? '');
    final departmentColor =
        departmentInfo?['color'] != null
            ? Color(departmentInfo!['color'])
            : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Refresh indicator
          if (isRefreshing)
            RotationTransition(
              turns: refreshAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: ModernTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Refreshing data...',
                      style: TextStyle(
                        color: ModernTheme.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Main header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getDepartmentIcon(userData?.department ?? ''),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData?.department ?? 'Department',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Official Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.more_vert, color: Colors.white),
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      _showProfile(context);
                      break;
                    case 'settings':
                      Navigator.pushNamed(context, '/settings');
                      break;
                    case 'analytics':
                      onShowAnalytics();
                      break;
                    case 'logout':
                      onSignOut();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person),
                            SizedBox(width: 12),
                            Text('Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'analytics',
                        child: Row(
                          children: [
                            Icon(Icons.analytics),
                            SizedBox(width: 12),
                            Text('Analytics'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 12),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Welcome message with verification status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: departmentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    userData?.isVerified == true
                        ? Icons.verified
                        : Icons.pending,
                    color: departmentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${userData?.shortDisplayName ?? 'Official'}!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ID: ${userData?.employeeId ?? 'N/A'} • ${userData?.accountStatus ?? 'Active'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (urgentCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ModernTheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$urgentCount URGENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ModernTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Official Profile'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileItem('Name', userData?.fullName ?? 'N/A'),
                _buildProfileItem('Email', userData?.email ?? 'N/A'),
                _buildProfileItem('Department', userData?.department ?? 'N/A'),
                _buildProfileItem('Employee ID', userData?.employeeId ?? 'N/A'),
                _buildProfileItem('Status', userData?.accountStatus ?? 'N/A'),
                _buildProfileItem(
                  'Member Since',
                  userData?.createdAt != null
                      ? _formatDate(userData!.createdAt!)
                      : 'N/A',
                ),
                if (userData?.verifiedAt != null)
                  _buildProfileItem(
                    'Verified On',
                    _formatDate(userData!.verifiedAt!),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
                child: const Text('Edit Profile'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ModernTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: ModernTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
