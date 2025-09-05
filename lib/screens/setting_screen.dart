// screens/settings_screen.dart (ENHANCED PROFESSIONAL VERSION)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../models/user_model.dart';
import '../theme/modern_theme.dart';
import 'citizen_help_support_screen.dart';
import 'admin_help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  UserModel? _userData;
  bool _isLoading = true;
  bool _isUpdating = false;

  // Settings state
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _locationEnabled = false;
  String _selectedLanguage = 'English';
  bool _isDarkMode = false;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  void _helpSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminHelpSupportScreen()),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load user data
      final userData = await _authService.getUserData();

      // Load settings from SettingsService
      await _settingsService.initializeSettings();

      // Load additional settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _userData = userData;
        _notificationsEnabled = _settingsService.notificationsEnabled;
        _selectedLanguage = _settingsService.selectedLanguage;
        _isDarkMode = _settingsService.isDarkMode;
        _soundEnabled = _settingsService.soundEnabled;

        // Load from SharedPreferences for settings not in SettingsService
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _locationEnabled = prefs.getBool('location_enabled') ?? false;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load settings: $e');
    }
  }

  Future<void> _updateUserProfile(
    String newName, {
    String? profilePictureUrl,
  }) async {
    setState(() => _isUpdating = true);

    try {
      Map<String, dynamic> updateData = {'fullName': newName};
      if (profilePictureUrl != null) {
        updateData['profilePicture'] = profilePictureUrl;
      }

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userData!.uid)
          .update(updateData);

      // Update local userData
      setState(() {
        _userData = UserModel(
          uid: _userData!.uid,
          email: _userData!.email,
          fullName: newName,
          userType: _userData!.userType,
          profilePicture: profilePictureUrl ?? _userData!.profilePicture,
          createdAt: _userData!.createdAt,
        );
      });

      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<String?> _uploadProfileImage(XFile imageFile) async {
    try {
      setState(() => _isUpdating = true);

      final fileName =
          'profile_${_userData!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      await ref.putFile(File(imageFile.path));
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      _showErrorSnackBar('Failed to upload image: $e');
      return null;
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (imageFile != null) {
        final downloadUrl = await _uploadProfileImage(imageFile);
        if (downloadUrl != null) {
          await _updateUserProfile(
            _userData!.fullName,
            profilePictureUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    setState(() => _isUpdating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);

        _showSuccessSnackBar('Password changed successfully!');
      }
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        _showErrorSnackBar('Current password is incorrect');
      } else if (e.toString().contains('weak-password')) {
        _showErrorSnackBar('New password is too weak');
      } else {
        _showErrorSnackBar('Failed to change password: $e');
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateNotificationSettings() async {
    setState(() => _isUpdating = true);

    try {
      // Update using SettingsService
      await _settingsService.setNotifications(_notificationsEnabled);

      // Save additional notification settings to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);

      _showSuccessSnackBar('Notification settings updated!');
    } catch (e) {
      _showErrorSnackBar('Failed to update settings: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateAppPreferences() async {
    setState(() => _isUpdating = true);

    try {
      // Update using SettingsService methods
      await _settingsService.setLanguage(_selectedLanguage);
      await _settingsService.setDarkMode(_isDarkMode);

      _showSuccessSnackBar('App preferences updated!');

      // Force app restart for immediate theme/language change
      if (mounted) {
        // Small delay to show the success message before restart
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update preferences: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updatePrivacySettings() async {
    setState(() => _isUpdating = true);

    try {
      // Save privacy settings to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_enabled', _locationEnabled);

      _showSuccessSnackBar('Privacy settings updated!');
    } catch (e) {
      _showErrorSnackBar('Failed to update privacy settings: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  // Enhanced Contact Support Dialog
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: ModernTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ModernTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.headset_mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ModernTheme.primaryBlue.withOpacity(0.1),
                        ModernTheme.primaryBlue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ModernTheme.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ModernTheme.primaryBlue.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: 32,
                          color: ModernTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Need assistance?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ModernTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our support team is here to help you with any questions or issues you may have.',
                        style: TextStyle(
                          fontSize: 14,
                          color: ModernTheme.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact Options
                _buildContactOption(
                  Icons.email,
                  'Email Support',
                  'civiclink.official@gmail.com',
                  'Send us a detailed message',
                  () {
                    Navigator.pop(context);
                    _launchEmailApp();
                  },
                ),
                const SizedBox(height: 12),
                _buildContactOption(
                  Icons.schedule,
                  'Response Time',
                  '24 hours',
                  'We typically respond within',
                  null,
                  isInfo: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _launchEmailApp();
                },
                icon: const Icon(Icons.email),
                label: const Text('Email Us'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildContactOption(
    IconData icon,
    String title,
    String value,
    String subtitle,
    VoidCallback? onTap, {
    bool isInfo = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isInfo ? ModernTheme.success.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isInfo
                  ? ModernTheme.success.withOpacity(0.2)
                  : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isInfo ? ModernTheme.success : ModernTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ModernTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isInfo
                                  ? ModernTheme.success
                                  : ModernTheme.primaryBlue,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ModernTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ModernTheme.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Simple email launcher using url_launcher_string
  Future<void> _launchEmailApp() async {
    final String emailUrl =
        'mailto:civiclink.official@gmail.com?subject=CivicLink Support Request&body=Hello CivicLink Support Team,%0D%0A%0D%0AI need assistance with:%0D%0A%0D%0A[Please describe your issue here]%0D%0A%0D%0AUser Details:%0D%0AAccount Type: ${_userData?.userType ?? 'Unknown'}%0D%0AEmail: ${_userData?.email ?? 'Unknown'}%0D%0A%0D%0AThank you!';

    try {
      bool launched = await launchUrlString(emailUrl);
      if (launched) {
        _showSuccessSnackBar('Opening email app...');
      } else {
        _showFallbackOptions();
      }
    } catch (e) {
      print('Email launch failed: $e');
      _showFallbackOptions();
    }
  }

  // Fallback if email app doesn't open
  void _showFallbackOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ModernTheme.primaryBlue,
                  size: 28,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Email App Not Available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We couldn\'t open your email app automatically. Here\'s what you can do:',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ModernTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.email,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'civiclink.official@gmail.com',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ModernTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ModernTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Manual Steps:\n1. Copy the email address above\n2. Open your email app (Gmail, Outlook, etc.)\n3. Create a new email\n4. Paste our email address\n5. Describe your issue and send',
                          style: TextStyle(
                            fontSize: 13,
                            color: ModernTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _copyEmailToClipboard();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Copy email to clipboard
  Future<void> _copyEmailToClipboard() async {
    const String email = 'civiclink.official@gmail.com';

    try {
      await Clipboard.setData(const ClipboardData(text: email));
      _showSuccessSnackBar('Email address copied to clipboard!');
    } catch (e) {
      _showErrorSnackBar('Failed to copy email address');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: ModernTheme.primaryGradient,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'Loading Settings...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildEnhancedProfileSection(),
                          const SizedBox(height: 32),
                          _buildAccountSettings(),
                          const SizedBox(height: 24),
                          _buildNotificationSettings(),
                          const SizedBox(height: 24),
                          _buildAppPreferences(),
                          const SizedBox(height: 24),
                          _buildPrivacySettings(),
                          const SizedBox(height: 24),
                          _buildEnhancedAboutSection(),
                          const SizedBox(height: 24),
                          _buildAccountManagement(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage your account and preferences',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isUpdating)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProfileSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ModernTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          _userData?.profilePicture?.isNotEmpty == true
                              ? Image.network(
                                _userData!.profilePicture!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      gradient: ModernTheme.primaryGradient,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _userData?.fullName.isNotEmpty == true
                                            ? _userData!.fullName[0]
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                              : Container(
                                decoration: const BoxDecoration(
                                  gradient: ModernTheme.primaryGradient,
                                ),
                                child: Center(
                                  child: Text(
                                    _userData?.fullName.isNotEmpty == true
                                        ? _userData!.fullName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ModernTheme.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ModernTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?.fullName ?? 'User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData?.email ?? 'user@example.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ModernStatusChip(
                          text: _userData?.userType?.toUpperCase() ?? 'USER',
                          color:
                              _userData?.userType == 'admin'
                                  ? ModernTheme.error
                                  : ModernTheme.accent,
                          icon:
                              _userData?.userType == 'admin'
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                        ),
                        const SizedBox(width: 8),
                        if (_userData?.createdAt != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ModernTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: ModernTheme.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Member since ${DateTime.fromMillisecondsSinceEpoch(_userData!.createdAt!.millisecondsSinceEpoch).year}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: ModernTheme.success,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isUpdating ? null : _showEnhancedEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ModernTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.photo_camera, size: 18),
                  label: const Text('Change Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ModernTheme.primaryBlue,
                    side: BorderSide(color: ModernTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return _buildSection('Account Settings', [
      _buildSettingsTile(
        icon: Icons.person_outline,
        title: 'Edit Profile',
        subtitle: 'Update your personal information',
        onTap: _showEnhancedEditProfileDialog,
      ),
      _buildSettingsTile(
        icon: Icons.lock_outline,
        title: 'Change Password',
        subtitle: 'Update your account password',
        onTap: _showEnhancedChangePasswordDialog,
      ),
    ]);
  }

  Widget _buildNotificationSettings() {
    return _buildSection('Notifications', [
      _buildSwitchTile(
        icon: Icons.notifications_outlined,
        title: 'Enable Notifications',
        subtitle: 'Receive app notifications',
        value: _notificationsEnabled,
        onChanged: (value) async {
          setState(() => _notificationsEnabled = value);
          await _updateNotificationSettings();
        },
      ),
      _buildSwitchTile(
        icon: Icons.email_outlined,
        title: 'Email Notifications',
        subtitle: 'Receive notifications via email',
        value: _emailNotifications,
        onChanged: (value) async {
          setState(() => _emailNotifications = value);
          await _updateNotificationSettings();
        },
      ),
      _buildSwitchTile(
        icon: Icons.phone_android,
        title: 'Push Notifications',
        subtitle: 'Receive push notifications',
        value: _pushNotifications,
        onChanged: (value) async {
          setState(() => _pushNotifications = value);
          await _updateNotificationSettings();
        },
      ),
    ]);
  }

  Widget _buildAppPreferences() {
    return _buildSection('App Preferences', [
      _buildDropdownTile(
        icon: Icons.language,
        title: 'Language',
        subtitle: 'Choose your preferred language',
        value: _selectedLanguage,
        items: const ['English', 'Sinhala'],
        onChanged: (value) async {
          setState(() => _selectedLanguage = value!);
          await _updateAppPreferences();
        },
      ),
      _buildSwitchTile(
        icon: Icons.dark_mode_outlined,
        title: 'Dark Mode',
        subtitle: 'Switch between light and dark theme',
        value: _isDarkMode,
        onChanged: (value) async {
          setState(() => _isDarkMode = value);
          await _updateAppPreferences();
        },
      ),
      _buildSwitchTile(
        icon: Icons.volume_up,
        title: 'Sound Effects',
        subtitle: 'Play sounds for notifications',
        value: _soundEnabled,
        onChanged: (value) async {
          setState(() => _soundEnabled = value);
          await _settingsService.setSoundEnabled(value);
        },
      ),
    ]);
  }

  Widget _buildPrivacySettings() {
    return _buildSection('Privacy & Security', [
      _buildSwitchTile(
        icon: Icons.location_on_outlined,
        title: 'Location Services',
        subtitle: 'Allow app to access your location',
        value: _locationEnabled,
        onChanged: (value) async {
          setState(() => _locationEnabled = value);
          await _updatePrivacySettings();
        },
      ),
      _buildSettingsTile(
        icon: Icons.security,
        title: 'Privacy Policy',
        subtitle: 'Read our privacy policy',
        onTap: _showEnhancedPrivacyPolicy,
      ),
    ]);
  }

  Widget _buildEnhancedAboutSection() {
    return _buildSection('About & Support', [
      _buildSettingsTile(
        icon: Icons.help_outline,
        title: 'Help & Support',
        subtitle: 'Get help or contact support',
        onTap: () => _helpSupport(context),
      ),
      _buildSettingsTile(
        icon: Icons.email_outlined,
        title: 'Contact Support',
        subtitle: 'Send email to our support team',
        onTap: _showContactSupportDialog,
      ),
      _buildSettingsTile(
        icon: Icons.info_outline,
        title: 'About CivicLink',
        subtitle: 'App version and information',
        onTap: _showEnhancedAboutApp,
      ),
      _buildSettingsTile(
        icon: Icons.feedback_outlined,
        title: 'Send Feedback',
        subtitle: 'Help us improve CivicLink',
        onTap: _showFeedbackDialog,
      ),
      _buildSettingsTile(
        icon: Icons.star_outline,
        title: 'Rate CivicLink',
        subtitle: 'Rate us on the app store',
        onTap: _rateApp,
      ),
    ]);
  }

  Widget _buildAccountManagement() {
    return _buildSection('Account Management', [
      _buildSettingsTile(
        icon: Icons.logout,
        title: 'Sign Out',
        subtitle: 'Sign out from your account',
        onTap: _signOut,
        textColor: ModernTheme.primaryBlue,
      ),
      _buildSettingsTile(
        icon: Icons.delete_outline,
        title: 'Delete Account',
        subtitle: 'Permanently remove your account',
        onTap: _deleteAccount,
        textColor: ModernTheme.error,
      ),
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? ModernTheme.primaryBlue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? ModernTheme.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color:
            textColor ??
            Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ModernTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ModernTheme.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ModernTheme.primaryBlue,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ModernTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ModernTheme.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: ModernTheme.primaryBlue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          underline: const SizedBox(),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          dropdownColor: Theme.of(context).cardColor,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  // Enhanced Edit Profile Dialog
  void _showEnhancedEditProfileDialog() {
    final nameController = TextEditingController(text: _userData?.fullName);
    final emailController = TextEditingController(text: _userData?.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: ModernTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ModernTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ModernTheme.primaryBlue.withOpacity(0.1),
                          ModernTheme.primaryBlue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ModernTheme.primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ModernTheme.primaryBlue.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    _userData?.profilePicture?.isNotEmpty ==
                                            true
                                        ? Image.network(
                                          _userData!.profilePicture!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              decoration: const BoxDecoration(
                                                gradient:
                                                    ModernTheme.primaryGradient,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _userData
                                                              ?.fullName
                                                              .isNotEmpty ==
                                                          true
                                                      ? _userData!.fullName[0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          decoration: const BoxDecoration(
                                            gradient:
                                                ModernTheme.primaryGradient,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _userData?.fullName.isNotEmpty ==
                                                      true
                                                  ? _userData!.fullName[0]
                                                      .toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: ModernTheme.primaryBlue,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap camera icon to change photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: ModernTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(
                          Icons.person,
                          color: ModernTheme.primaryBlue,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        helperText: 'Email cannot be changed',
                        helperStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      enabled: false,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty && newName != _userData?.fullName) {
                    Navigator.pop(context);
                    await _updateUserProfile(newName);
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
    );
  }

  // Enhanced Change Password Dialog
  void _showEnhancedChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Theme.of(context).cardColor,
                  title: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: ModernTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: ModernTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ModernTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ModernTheme.primaryBlue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: ModernTheme.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'For security, you need to enter your current password to make changes.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ModernTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: currentPasswordController,
                            obscureText: obscureCurrentPassword,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: ModernTheme.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureCurrentPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureCurrentPassword =
                                        !obscureCurrentPassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: newPasswordController,
                            obscureText: obscureNewPassword,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: ModernTheme.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureNewPassword = !obscureNewPassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: ModernTheme.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ModernTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password Requirements:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ModernTheme.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '• At least 8 characters long\n• Include uppercase and lowercase letters\n• Include at least one number\n• Include at least one special character',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ModernTheme.success,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final currentPassword =
                            currentPasswordController.text.trim();
                        final newPassword = newPasswordController.text.trim();
                        final confirmPassword =
                            confirmPasswordController.text.trim();

                        if (currentPassword.isEmpty ||
                            newPassword.isEmpty ||
                            confirmPassword.isEmpty) {
                          _showErrorSnackBar('All fields are required');
                          return;
                        }

                        if (newPassword != confirmPassword) {
                          _showErrorSnackBar('New passwords do not match');
                          return;
                        }

                        if (newPassword.length < 8) {
                          _showErrorSnackBar(
                            'Password must be at least 8 characters long',
                          );
                          return;
                        }

                        Navigator.pop(context);
                        await _changePassword(currentPassword, newPassword);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModernTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Change Password'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Enhanced Privacy Policy Dialog
  void _showEnhancedPrivacyPolicy() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: ModernTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ModernTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ModernTheme.primaryBlue.withOpacity(0.1),
                            ModernTheme.primaryBlue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ModernTheme.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: ModernTheme.primaryBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Your privacy is our priority. We are committed to protecting your personal information.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ModernTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildPrivacySection(
                      'Information We Collect',
                      '• Personal information (name, email address)\n• Location data (when you report issues)\n• Device information and app usage data\n• Content you create (issue reports, comments)',
                      Icons.info_outline,
                    ),

                    _buildPrivacySection(
                      'How We Use Your Information',
                      '• To provide and improve our services\n• To process and respond to your reports\n• To send important notifications\n• To ensure app security and prevent fraud',
                      Icons.build,
                    ),

                    _buildPrivacySection(
                      'Information Sharing',
                      '• We do not sell your personal information\n• We may share data with government authorities for issue resolution\n• We use secure third-party services (Firebase, etc.)\n• Anonymous usage statistics may be shared',
                      Icons.share,
                    ),

                    _buildPrivacySection(
                      'Data Security',
                      '• End-to-end encryption for sensitive data\n• Regular security audits and updates\n• Secure cloud storage with Firebase\n• Limited access to authorized personnel only',
                      Icons.lock,
                    ),

                    _buildPrivacySection(
                      'Your Rights',
                      '• Access your personal data anytime\n• Request data correction or deletion\n• Control notification preferences\n• Opt-out of non-essential data collection',
                      Icons.person_outline,
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ModernTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ModernTheme.success.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.update,
                                color: ModernTheme.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Last Updated: August 2025',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ModernTheme.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We may update this policy from time to time. We will notify you of any significant changes.',
                            style: TextStyle(
                              fontSize: 12,
                              color: ModernTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _launchUrlString('https://civiclink.com/privacy');
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Full Policy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPrivacySection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ModernTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: ModernTheme.primaryBlue, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: ModernTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced About App Dialog
  void _showEnhancedAboutApp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height *
                    0.8, // Limit height to 80% of screen
              ),
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: ModernTheme.primaryGradient,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_city,
                              size: 40,
                              color: ModernTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'CivicLink',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🏛️ Report. Track. Resolve.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About CivicLink',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ModernTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ModernTheme.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ModernTheme.primaryBlue.withOpacity(0.1),
                              ),
                            ),
                            child: const Text(
                              'CivicLink bridges the gap between citizens and local authorities, making community problem-solving efficient and transparent. Report issues, track progress, and help build better communities.',
                              style: TextStyle(
                                fontSize: 14,
                                color: ModernTheme.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildFeatureItem(
                            Icons.report_problem,
                            'Smart Issue Reporting',
                            'Report community problems with photos and location data',
                          ),
                          _buildFeatureItem(
                            Icons.track_changes,
                            'Real-time Tracking',
                            'Monitor the progress of your reported issues',
                          ),
                          _buildFeatureItem(
                            Icons.map,
                            'Interactive Maps',
                            'Visualize community issues on detailed maps',
                          ),
                          _buildFeatureItem(
                            Icons.notifications_active,
                            'Instant Notifications',
                            'Get updates when issues are resolved',
                          ),
                          _buildFeatureItem(
                            Icons.dashboard,
                            'Admin Dashboard',
                            'Comprehensive management tools for authorities',
                          ),

                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              '© 2025 CivicLink Team\nMade with ❤️ for better communities',
                              style: TextStyle(
                                fontSize: 12,
                                color: ModernTheme.textSecondary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ModernTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ModernTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Additional new methods
  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.feedback, color: ModernTheme.primaryBlue),
                SizedBox(width: 12),
                Text('Send Feedback'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Help us improve CivicLink! Your feedback is valuable to us.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    hintText:
                        'Share your thoughts, suggestions, or report bugs...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _launchEmailApp();
                  _showSuccessSnackBar('Opening email to send feedback...');
                },
                child: const Text('Send Feedback'),
              ),
            ],
          ),
    );
  }

  void _rateApp() {
    // Simulate app store rating
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.star, color: Colors.orange),
                SizedBox(width: 12),
                Text('Rate CivicLink'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enjoying CivicLink? Please take a moment to rate us on the app store!',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 30),
                    Icon(Icons.star, color: Colors.orange, size: 30),
                    Icon(Icons.star, color: Colors.orange, size: 30),
                    Icon(Icons.star, color: Colors.orange, size: 30),
                    Icon(Icons.star, color: Colors.orange, size: 30),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessSnackBar('Thank you for your support!');
                },
                child: const Text('Rate Now'),
              ),
            ],
          ),
    );
  }

  // Action Methods
  void _editProfile() {
    _showEnhancedEditProfileDialog();
  }

  void _signOut() async {
    _showDialog(
      'Sign Out',
      '👋 Are you sure you want to sign out?\n\n'
          'You can always sign back in anytime to continue reporting '
          'and tracking community issues.',
      showActions: true,
      confirmText: 'Sign Out',
      onConfirm: () async {
        try {
          setState(() => _isUpdating = true);
          await _authService.signOut();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        } catch (e) {
          setState(() => _isUpdating = false);
          _showErrorSnackBar('Failed to sign out: $e');
        }
      },
    );
  }

  void _deleteAccount() {
    _showDialog(
      'Delete Account',
      '⚠️ This action cannot be undone!\n\n'
          'Deleting your account will permanently remove:\n'
          '• Your profile information\n'
          '• All reported issues\n'
          '• App settings and preferences\n'
          '• Activity history\n\n'
          'Are you absolutely sure you want to delete your account?',
      showActions: true,
      confirmText: 'Delete Account',
      isDestructive: true,
      onConfirm: () {
        _showDialog(
          'Account Deletion',
          'Account deletion is a permanent action. To proceed, please contact our support team at civiclink.official@gmail.com with your deletion request.\n\n'
              'We\'ll process your request within 48 hours and send you a confirmation email.',
        );
      },
    );
  }

  void _showDialog(
    String title,
    String content, {
    bool showActions = false,
    String confirmText = 'OK',
    bool isDestructive = false,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            content: Text(
              content,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            actions: [
              if (showActions) ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm?.call();
                  },
                  style:
                      isDestructive
                          ? ElevatedButton.styleFrom(
                            backgroundColor: ModernTheme.error,
                            foregroundColor: Colors.white,
                          )
                          : null,
                  child: Text(confirmText),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ModernTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ModernTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _launchUrlString(String url) async {
    try {
      await launchUrlString(url);
    } catch (e) {
      _showErrorSnackBar('Could not open link');
    }
  }
}
