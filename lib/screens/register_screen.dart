// screens/register_screen.dart (ENHANCED WITH DEPARTMENT SELECTION)
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedUserType = 'citizen';
  String _selectedDepartment = '';

  // Department list matching your issue categories
  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'Road & Transportation',
      'icon': Icons.construction,
      'color': ModernTheme.warning,
      'description': 'Roads, bridges, traffic systems',
    },
    {
      'name': 'Water & Sewerage',
      'icon': Icons.water_drop,
      'color': ModernTheme.primaryBlue,
      'description': 'Water supply, drainage, sewerage',
    },
    {
      'name': 'Electricity',
      'icon': Icons.electrical_services,
      'color': ModernTheme.accent,
      'description': 'Power supply, electrical infrastructure',
    },
    {
      'name': 'Public Safety',
      'icon': Icons.security,
      'color': ModernTheme.error,
      'description': 'Police, fire, emergency services',
    },
    {
      'name': 'Waste Management',
      'icon': Icons.delete,
      'color': ModernTheme.success,
      'description': 'Garbage collection, recycling',
    },
    {
      'name': 'Parks & Recreation',
      'icon': Icons.park,
      'color': Color(0xFF4CAF50),
      'description': 'Parks, playgrounds, recreation facilities',
    },
    {
      'name': 'Street Lighting',
      'icon': Icons.lightbulb,
      'color': Color(0xFFFFC107),
      'description': 'Street lights, public lighting',
    },
    {
      'name': 'Public Buildings',
      'icon': Icons.business,
      'color': Color(0xFF9C27B0),
      'description': 'Government buildings, public facilities',
    },
    {
      'name': 'Traffic Management',
      'icon': Icons.traffic,
      'color': Color(0xFFFF5722),
      'description': 'Traffic signals, road signs',
    },
    {
      'name': 'Environmental Issues',
      'icon': Icons.eco,
      'color': Color(0xFF8BC34A),
      'description': 'Environmental protection, pollution',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Set default department to first one
    _selectedDepartment = _departments.first['name'];
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
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

      // Use test registration method
      final result = await _authService.testRegistration(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ModernTheme.gradientStart, ModernTheme.gradientEnd],
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
                    const SizedBox(height: 40),
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
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
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add,
              size: 40,
              color: ModernTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Join CivicLink',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: const Text(
            'Create your account',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return ModernCard(
      elevated: true,
      borderRadius: BorderRadius.circular(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ModernTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below to get started',
              style: TextStyle(
                fontSize: 15,
                color: ModernTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Full Name Field
            TextFormField(
              controller: _fullNameController,
              style: const TextStyle(fontSize: 16),
              decoration: _buildInputDecoration(
                'Full Name',
                'Enter your full name',
                Icons.person_outline,
              ),
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

            const SizedBox(height: 18),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16),
              decoration: _buildInputDecoration(
                'Email Address',
                'Enter your email',
                Icons.email_outlined,
              ),
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

            const SizedBox(height: 20),

            // Account Type Selection
            _buildAccountTypeSelection(),

            // Show department selection and employee ID for officials
            if (_selectedUserType == 'official') ...[
              const SizedBox(height: 20),
              _buildDepartmentSelection(),
              const SizedBox(height: 18),
              _buildEmployeeIdField(),
            ],

            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 16),
              decoration: _buildInputDecoration(
                'Password',
                'Enter your password',
                Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: ModernTheme.textSecondary,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
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

            const SizedBox(height: 18),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(fontSize: 16),
              decoration: _buildInputDecoration(
                'Confirm Password',
                'Confirm your password',
                Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: ModernTheme.textSecondary,
                  ),
                  onPressed:
                      () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
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

            const SizedBox(height: 28),

            // Create Account Button
            GradientButton(
              text: 'Create Account',
              onPressed: _register,
              isLoading: _isLoading,
              icon: Icons.person_add,
              gradient: ModernTheme.primaryGradient,
              height: 52,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String labelText,
    String hintText,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ModernTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ModernTheme.primaryBlue, size: 20),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildAccountTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient:
                        _selectedUserType == 'citizen'
                            ? ModernTheme.accentGradient
                            : null,
                    color:
                        _selectedUserType == 'citizen'
                            ? null
                            : ModernTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _selectedUserType == 'citizen'
                              ? Colors.transparent
                              : ModernTheme.textTertiary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow:
                        _selectedUserType == 'citizen'
                            ? [
                              BoxShadow(
                                color: ModernTheme.accent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _selectedUserType == 'citizen'
                                  ? Colors.white.withOpacity(0.2)
                                  : ModernTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          color:
                              _selectedUserType == 'citizen'
                                  ? Colors.white
                                  : ModernTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Citizen',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'citizen'
                                  ? Colors.white
                                  : ModernTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Report community issues',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'citizen'
                                  ? Colors.white.withOpacity(0.9)
                                  : ModernTheme.textSecondary,
                          fontSize: 12,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient:
                        _selectedUserType == 'official'
                            ? ModernTheme.primaryGradient
                            : null,
                    color:
                        _selectedUserType == 'official'
                            ? null
                            : ModernTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _selectedUserType == 'official'
                              ? Colors.transparent
                              : ModernTheme.textTertiary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow:
                        _selectedUserType == 'official'
                            ? [
                              BoxShadow(
                                color: ModernTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _selectedUserType == 'official'
                                  ? Colors.white.withOpacity(0.2)
                                  : ModernTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.badge,
                          color:
                              _selectedUserType == 'official'
                                  ? Colors.white
                                  : ModernTheme.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Official',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'official'
                                  ? Colors.white
                                  : ModernTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage department issues',
                        style: TextStyle(
                          color:
                              _selectedUserType == 'official'
                                  ? Colors.white.withOpacity(0.9)
                                  : ModernTheme.textSecondary,
                          fontSize: 12,
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: ModernTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ModernTheme.primaryBlue.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: ModernTheme.primaryBlue,
              ),
              style: const TextStyle(
                fontSize: 16,
                color: ModernTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: ModernTheme.surface,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 300,
              items:
                  _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department['name'],
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (department['color'] as Color)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                department['icon'],
                                size: 18,
                                color: department['color'],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    department['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    department['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ModernTheme.textSecondary,
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

  Widget _buildEmployeeIdField() {
    return TextFormField(
      controller: _employeeIdController,
      style: const TextStyle(fontSize: 16),
      decoration: _buildInputDecoration(
        'Employee ID',
        'Enter your official employee ID',
        Icons.badge_outlined,
      ),
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
    );
  }

  Widget _buildLoginLink() {
    return ModernCard(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Already have an account? ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
