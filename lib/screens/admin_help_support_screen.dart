import 'package:flutter/material.dart';

class AdminHelpSupportScreen extends StatefulWidget {
  const AdminHelpSupportScreen({super.key});

  @override
  State<AdminHelpSupportScreen> createState() => _AdminHelpSupportScreenState();
}

class _AdminHelpSupportScreenState extends State<AdminHelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140), // adjust AppBar height
        child: AppBar(
          title: const Text(
            "Help & User Guide",
            style: TextStyle(
              fontSize: 25, // change size here
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true, // centers the title
          backgroundColor: const Color.fromARGB(232, 78, 52, 122),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white, // underline color
            labelColor: const Color.fromARGB(
              255,
              245,
              244,
              184,
            ), // active tab text
            unselectedLabelColor: const Color.fromARGB(
              167,
              255,
              255,
              255,
            ), // inactive tab text
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold, // active tab font
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal, // inactive tab font
            ),
            tabs: const [
              Tab(text: "Getting Started"),
              Tab(text: "Issue Management"),
              Tab(text: "Analytics & Teams"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ============= TAB 1: Getting Started ============
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                title: "Welcome Admin!",
                description:
                    "Thank you for registering as an Admin in CivicLink. "
                    "Admins play a key role in managing issues, tracking performance, "
                    "and supporting their departments.",
                icon: Icons.admin_panel_settings,
              ),
              _buildCard(
                title: "Register as Admin",
                description:
                    "To use admin features, you must first register and verify "
                    "your account as an admin of your department.",
                icon: Icons.badge,
              ),
            ],
          ),

          // ============= TAB 2: Issue Management ============
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                title: "Pending Issues",
                description:
                    "View all issues submitted by citizens that are awaiting action. "
                    "You can prioritize them or assign to team members.",
                icon: Icons.pending_actions,
              ),
              _buildCard(
                title: "Urgent Issues",
                description:
                    "Monitor high-priority issues that require immediate attention "
                    "from your department.",
                icon: Icons.priority_high,
              ),
              _buildCard(
                title: "Assigned to You",
                description:
                    "See issues currently assigned to you for resolution. "
                    "Track their progress and update status.",
                icon: Icons.assignment_ind,
              ),
              _buildCard(
                title: "In Progress",
                description:
                    "Follow issues that are currently being worked on by your department. "
                    "Update notes and share progress.",
                icon: Icons.work,
              ),
              _buildCard(
                title: "Resolved Issues",
                description:
                    "Review the issues successfully solved by you or your department. "
                    "Use this for tracking performance.",
                icon: Icons.check_circle,
              ),
              _buildCard(
                title: "Notifications",
                description:
                    "Stay updated with notifications about new issues, assignments, "
                    "and deadlines.",
                icon: Icons.notifications_active,
              ),
            ],
          ),

          // ============= TAB 3: Analytics & Teams ============
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                title: "Performance Metrics",
                description:
                    "Gain insights into your department’s performance:\n"
                    "• Resolution Rate\n"
                    "• Average Resolution Time\n"
                    "• Total Issues Assigned",
                icon: Icons.analytics,
              ),
              _buildCard(
                title: "Department Analytics",
                description:
                    "View analytics about your department’s workload, bottlenecks, "
                    "and citizen satisfaction trends.",
                icon: Icons.insights,
              ),
              _buildCard(
                title: "Team Collaboration",
                description:
                    "Work together as teams by assigning tasks, monitoring progress, "
                    "and ensuring accountability.",
                icon: Icons.groups,
              ),
              _buildCard(
                title: "Assign Tasks",
                description:
                    "Assign specific issues to team members in your department "
                    "and track their completion.",
                icon: Icons.task,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
