// screens/register_screen.dart (ENHANCED UI - MORE ATTRACTIVE & COLORFUL - COMPLETE)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/modern_theme.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final AuthService _authService = AuthService();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedUserType = 'citizen';
  String _selectedDepartment = '';

  // Updated department list - reduced to 5 departments as requested
  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'Public Safety',
      'icon': Icons.security,
      'color': const Color(0xFFE91E63), // Pink
      'description': '',
      'gradient': const LinearGradient(
        colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
      ),
    },
    {
      'name': 'Electricity and Power',
      'icon': Icons.electrical_services,
      'color': const Color(0xFFFF9800), // Orange
      'description': '',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFCC02)],
      ),
    },
    {
      'name': 'Water and Sewage',
      'icon': Icons.water_drop,
      'color': const Color(0xFF2196F3), // Blue
      'description': '',
      'gradient': const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF03DAC6)],
      ),
    },
    {
      'name': 'Road and Transportation',
      'icon': Icons.construction,
      'color': const Color(0xFF9C27B0), // Purple
      'description': '',
      'gradient': const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
      ),
    },
    {
      'name': 'Environmental Issues',
      'icon': Icons.eco,
      'color': const Color(0xFF4CAF50), // Green
      'description': '',
      'gradient': const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Set default department to first one
    _selectedDepartment = _departments.first['name'];
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _employeeIdController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for official accounts
    if (_selectedUserType == 'official') {
      if (_selectedDepartment.isEmpty) {
        _showErrorSnackBar('Please select a department');
        return;
      }
      if (_employeeIdController.text.trim().isEmpty) {
        _showErrorSnackBar('Employee ID is required for official accounts');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      print("🚀 Starting registration process...");
      print("📧 Email: ${_emailController.text}");
      print("👤 Name: ${_fullNameController.text}");
      print("🏷️ Type: $_selectedUserType");

      if (_selectedUserType == 'official') {
        print("🏢 Department: $_selectedDepartment");
        print("🆔 Employee ID: ${_employeeIdController.text.trim()}");
      }

      final result = await _authService.registerWithEmail(
        _emailController.text,
        _passwordController.text,
        _fullNameController.text,
        _selectedUserType,
        department:
            _selectedUserType == 'official' ? _selectedDepartment : null,
        employeeId:
            _selectedUserType == 'official'
                ? _employeeIdController.text.trim()
                : null,
      );

      print("✅ Registration completed successfully");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Account created successfully!'),
            ],
          ),
          backgroundColor: ModernTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("❌ Registration failed: $e");
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF11998e), // Teal
              Color(0xFF38ef7d), // Light green
              Color(0xFF667eea), // Purple-blue
              Color(0xFFf093fb), // Pink
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildRegisterForm(),
                    const SizedBox(height: 32),
                    _buildLoginLink(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        ScaleTransition(
          scale: _bounceAnimation,
          child: Hero(
            tag: 'app_logo',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF38ef7d), // Light green
                    Color(0xFF11998e), // Teal
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFF38ef7d).withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add,
                size: 45,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Join CivicLink',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.2,
            shadows: [
              Shadow(
                offset: Offset(0, 4),
                blurRadius: 8,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            'Create your account',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return ModernCard(
      elevated: true,
      borderRadius: BorderRadius.circular(28),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: ModernTheme.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below to get started',
              style: TextStyle(
                fontSize: 16,
                color: ModernTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Full Name Field
            _buildEnhancedTextField(
              controller: _fullNameController,
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              icon: Icons.person_outline,
              gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Email Field
            _buildEnhancedTextField(
              controller: _emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Account Type Selection
            _buildAccountTypeSelection(),

            // Show department selection and employee ID for officials
            if (_selectedUserType == 'official') ...[
              const SizedBox(height: 24),
              _buildDepartmentSelection(),
              const SizedBox(height: 20),
              _buildEnhancedTextField(
                controller: _employeeIdController,
                labelText: 'Employee ID',
                hintText: 'Enter your official employee ID',
                icon: Icons.badge_outlined,
                gradientColors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                validator: (value) {
                  if (_selectedUserType == 'official') {
                    if (value == null || value.trim().isEmpty) {
                      return 'Employee ID is required for official accounts';
                    }
                    if (value.trim().length < 3) {
                      return 'Employee ID must be at least 3 characters';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Password Field
            _buildEnhancedTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFf093fb),
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Confirm Password Field
            _buildEnhancedTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              gradientColors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: const Color(0xFFE91E63),
                ),
                onPressed:
                    () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Create Account Button
            GradientButton(
              text: 'Create Account',
              onPressed: _register,
              isLoading: _isLoading,
              icon: Icons.person_add,
              gradient: const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              ),
              height: 56,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required List<Color> gradientColors,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          filled: true,
          fillColor: const Color(0xFFF8F9FF),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gradientColors.first, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildAccountTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap:
                    () => setState(() {
                      _selectedUserType = 'citizen';
                      _selectedDepartment = _departments.first['name'];
                    }),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient:
                        _selectedUserType == 'citizen'
                            ? const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            )
                            : null,
                    color:
                        _selectedUserType == 'citizen'
                            ? null
                            : const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _selectedUserType == 'citizen'
                              ? Colors.transparent
                              : const Color(0xFF667eea).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow:
                        _selectedUserType == 'citizen'
                            ? [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ]
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient:
                              _selectedUserType == 'citizen'
                                  ? LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  )
                                  : const LinearGradient(
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.person,
                          color:
                              _selectedUserType == 'citizen'
                                  ? Colors.white
                                  : Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Citizen',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'citizen'
                                  ? Colors.white
                                  : ModernTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Report community issues',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'citizen'
                                  ? Colors.white.withOpacity(0.9)
                                  : ModernTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap:
                    () => setState(() {
                      _selectedUserType = 'official';
                      _selectedDepartment = _departments.first['name'];
                    }),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient:
                        _selectedUserType == 'official'
                            ? const LinearGradient(
                              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                            )
                            : null,
                    color:
                        _selectedUserType == 'official'
                            ? null
                            : const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _selectedUserType == 'official'
                              ? Colors.transparent
                              : const Color(0xFF11998e).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow:
                        _selectedUserType == 'official'
                            ? [
                              BoxShadow(
                                color: const Color(0xFF11998e).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ]
                            : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient:
                              _selectedUserType == 'official'
                                  ? LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  )
                                  : const LinearGradient(
                                    colors: [
                                      Color(0xFF11998e),
                                      Color(0xFF38ef7d),
                                    ],
                                  ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.badge, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Official',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'official'
                                  ? Colors.white
                                  : ModernTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage department issues',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'official'
                                  ? Colors.white.withOpacity(0.9)
                                  : ModernTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepartmentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFF8F9FF), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF9C27B0).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: ModernTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              menuMaxHeight: 280,
              itemHeight: 60,
              items:
                  _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department['name'],
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: department['gradient'],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                department['icon'],
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    department['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    department['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ModernTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedDepartment = newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Already have an account? ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf093fb).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Required supporting widgets
class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool elevated;

  const ModernCard({
    Key? key,
    required this.child,
    this.color,
    this.borderRadius,
    this.elevated = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow:
            elevated
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: const Color(0xFF11998e).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
      ),
      child: Padding(padding: const EdgeInsets.all(28), child: child),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final LinearGradient gradient;
  final double height;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    required this.gradient,
    this.height = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.8,
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
