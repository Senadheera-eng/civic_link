import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final User? user = FirebaseAuth.instance.currentUser;

  String userName = '';
  String email = '';
  String role = '';
  String joinedDate = '';
  int reportsSubmitted = 0;

  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();
    final data = doc.data();

    setState(() {
      userName = data?['fullName'] ?? 'No name';
      email = user?.email ?? 'No email';
      role = data?['role'] ?? 'Citizen';
      _nameController.text = userName;

      Timestamp? ts = data?['createdAt'];
      if (ts != null) {
        final dt = ts.toDate();
        joinedDate = '${dt.day} ${_monthName(dt.month)}, ${dt.year}';
      }
    });

    final reportsQuery =
        await FirebaseFirestore.instance
            .collection('issues')
            .where('userId', isEqualTo: user?.uid)
            .get();

    setState(() {
      reportsSubmitted = reportsQuery.docs.length;
    });
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _image = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveName() async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'fullName': _nameController.text.trim()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 241, 245),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: Container(
          padding: const EdgeInsets.only(
            top: 50,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your personal info',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      body:
          user == null
              ? const Center(child: Text('User not logged in'))
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor:
                                  _image == null
                                      ? const Color(0xFF2962FF)
                                      : null,
                              backgroundImage:
                                  _image != null ? FileImage(_image!) : null,
                              child:
                                  _image == null
                                      ? Text(
                                        userName.isNotEmpty
                                            ? userName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Colors.white,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 8,
                            child: InkWell(
                              onTap: _showEditOptions,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Full Name",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _saveName,
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text("Save"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildInfoTile(Icons.email, "Email", email),
                    _buildInfoTile(Icons.verified_user, "Role", role),
                    _buildInfoTile(
                      Icons.calendar_today,
                      "Joined Date",
                      joinedDate,
                    ),
                    _buildInfoTile(
                      Icons.analytics,
                      "Reports Submitted",
                      "$reportsSubmitted reports",
                    ),
                    const SizedBox(height: 20),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.lock, color: Colors.blue),
                        title: const Text("Change Password"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPassword,
      );
      await user!.reauthenticateWithCredential(cred);
      await user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updatePassword,
                child: const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
