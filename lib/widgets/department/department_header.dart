// widgets/department/department_header.dart (UPDATED VERSION)
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/modern_theme.dart';
import '../../screens/admin_help_support_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Top row with welcome and actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData?.fullName ?? 'Official',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${userData?.department ?? 'Unknown'} Department',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                children: [
                  // Settings button - UPDATED to use OfficialSettingsScreen
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      tooltip: 'Settings',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Analytics button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.analytics, color: Colors.white),
                      onPressed: onShowAnalytics,
                      tooltip: 'Analytics',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Profile/Menu button
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'profile':
                          _showProfileDialog(context);
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
                                Icon(Icons.person_outline),
                                SizedBox(width: 12),
                                Text('View Profile'),
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
                                Text(
                                  'Sign Out',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status indicators
          Row(
            children: [
              // Refresh indicator
              if (isRefreshing)
                AnimatedBuilder(
                  animation: refreshAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: refreshAnimation.value * 2 * 3.14159,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),
              if (isRefreshing) const SizedBox(width: 12),

              // Urgent issues indicator
              if (urgentCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$urgentCount Urgent',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Online status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Profile Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileRow('Name', userData?.fullName ?? 'N/A'),
                _buildProfileRow('Email', userData?.email ?? 'N/A'),
                _buildProfileRow('Department', userData?.department ?? 'N/A'),
                _buildProfileRow('Role', 'Department Official'),
                _buildProfileRow(
                  'Status',
                  userData?.isVerified == true ? 'Verified' : 'Pending',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
