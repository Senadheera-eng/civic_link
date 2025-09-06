// screens/modern_report_issue_screen.dart (UPDATED FOR 5 DEPARTMENTS - ERROR FREE)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';

class ModernReportIssueScreen extends StatefulWidget {
  const ModernReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<ModernReportIssueScreen> createState() =>
      _ModernReportIssueScreenState();
}

class _ModernReportIssueScreenState extends State<ModernReportIssueScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final IssueService _issueService = IssueService();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form data
  late String _selectedCategory;
  late String _selectedPriority;
  List<XFile> _selectedImages = [];
  Position? _currentLocation;
  String _address = '';

  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _selectedCategory = IssueCategories.categories.first;
    _selectedPriority =
        IssuePriorities.priorities.length > 1
            ? IssuePriorities.priorities[1]
            : IssuePriorities.priorities.first;
    _getCurrentLocation();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _titleController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable them in settings.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      final position = await _issueService.getCurrentLocation();
      final address = await _issueService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentLocation = position;
          _address = address;
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        _showErrorSnackBar('Location error: ${e.toString()}');
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _issueService.pickImageFromCamera();
      if (image != null && mounted) {
        setState(() => _selectedImages.add(image));
      }
    } catch (e) {
      _showErrorSnackBar('Camera error: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _issueService.pickImageFromGallery();
      if (image != null && mounted) {
        setState(() => _selectedImages.add(image));
      }
    } catch (e) {
      _showErrorSnackBar('Gallery error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentLocation == null) {
      _showErrorSnackBar('Please wait for location to be detected');
      return;
    }

    if (_selectedImages.isEmpty) {
      final shouldContinue = await _showConfirmDialog(
        'No Images',
        'Are you sure you want to submit without any images?',
      );
      if (shouldContinue != true) return;
    }

    setState(() => _isLoading = true);

    try {
      // DEBUG: Print the selected category to verify it's correct
      print("🎯 DEBUG: Selected Category = '$_selectedCategory'");
      print("🎯 DEBUG: Available Categories = ${IssueCategories.categories}");
      print(
        "🎯 DEBUG: Category Index = ${IssueCategories.categories.indexOf(_selectedCategory)}",
      );

      // Verify the category is valid
      if (!IssueCategories.categories.contains(_selectedCategory)) {
        throw Exception('Invalid category selected: $_selectedCategory');
      }

      print("🚀 Submitting issue...");
      print("📁 Title: ${_titleController.text.trim()}");
      print("📁 Category: $_selectedCategory");
      print("📁 Priority: $_selectedPriority");
      print("📁 Description: ${_descriptionController.text.trim()}");

      final issueId = await _issueService.submitIssue(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category:
            _selectedCategory, // Make sure this is the exact category name
        priority: _selectedPriority,
        images: _selectedImages,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        address: _address,
      );

      print("✅ Issue submitted successfully with ID: $issueId");
      print("✅ Issue should be routed to department: $_selectedCategory");

      if (mounted) {
        _showSuccessSnackBar(
          'Issue submitted to $_selectedCategory department!',
        );
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("❌ Failed to submit issue: $e");
      _showErrorSnackBar('Failed to submit issue: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: ModernTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, true),
                    borderRadius: BorderRadius.circular(8),
                    child: const Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ModernTheme.primaryBlue, ModernTheme.background],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      decoration: const BoxDecoration(
                        color: ModernTheme.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildLocationStatus(),
                              const SizedBox(height: 32),
                              _buildTitleField(),
                              const SizedBox(height: 24),
                              _buildCategorySection(),
                              const SizedBox(height: 24),
                              _buildPrioritySection(),
                              const SizedBox(height: 24),
                              _buildDescriptionField(),
                              const SizedBox(height: 32),
                              _buildImageSection(),
                              const SizedBox(height: 40),
                              _buildSubmitButton(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                  'Report Issue',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Help improve your community',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
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

  Widget _buildLocationStatus() {
    return _ModernCard(
      color:
          _currentLocation != null
              ? ModernTheme.success.withOpacity(0.1)
              : ModernTheme.warning.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient:
                  _currentLocation != null
                      ? ModernTheme.successGradient
                      : ModernTheme.warningGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _currentLocation != null ? Icons.location_on : Icons.location_off,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentLocation != null
                      ? 'Location Detected'
                      : 'Getting Location...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color:
                        _currentLocation != null
                            ? ModernTheme.success
                            : ModernTheme.warning,
                  ),
                ),
                if (_address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ModernTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isGettingLocation)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ModernTheme.warning,
              ),
            )
          else if (_currentLocation != null)
            IconButton(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh, color: ModernTheme.success),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Issue Title',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Brief description of the issue...',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.title,
                color: ModernTheme.primaryBlue,
                size: 20,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 5) {
              return 'Title must be at least 5 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the department that can help resolve this issue',
          style: TextStyle(fontSize: 14, color: ModernTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // Enhanced category grid layout
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: IssueCategories.categories.length,
          itemBuilder: (context, index) {
            final category = IssueCategories.categories[index];
            final isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      isSelected ? _getGradientForCategory(category) : null,
                  color: isSelected ? null : ModernTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? Colors.transparent
                            : Color(
                              IssueCategories.getColorValue(category),
                            ).withOpacity(0.3),
                    width: isSelected ? 0 : 1.5,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Color(
                                IssueCategories.getColorValue(category),
                              ).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12), // Reduced from 16
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10), // Reduced from 12
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : Color(
                                    IssueCategories.getColorValue(category),
                                  ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          IssueCategories.getIcon(category),
                          style: const TextStyle(
                            fontSize: 20,
                          ), // Reduced from 24
                        ),
                      ),
                      const SizedBox(height: 8), // Reduced from 12
                      Text(
                        category,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : ModernTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12, // Reduced from 13
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 2), // Reduced from 4
                        Flexible(
                          // Added Flexible to prevent overflow
                          child: Text(
                            IssueCategories.getDescription(category),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 9, // Reduced from 10
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children:
              IssuePriorities.priorities.map((priority) {
                final isSelected = _selectedPriority == priority;
                final priorityColor = Color(
                  IssuePriorities.getColorValue(priority),
                );

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPriority = priority),
                    child: Container(
                      margin: EdgeInsets.only(
                        right:
                            priority != IssuePriorities.priorities.last ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? priorityColor.withOpacity(0.1)
                                : ModernTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? priorityColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            priority,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? priorityColor
                                      : ModernTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Provide detailed description of the issue...',
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ModernTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add photos to help authorities understand the issue better',
          style: TextStyle(fontSize: 14, color: ModernTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // Image Action Buttons
        Row(
          children: [
            Expanded(
              child: _GradientButton(
                text: 'Camera',
                icon: Icons.camera_alt,
                onPressed: _pickImageFromCamera,
                gradient: ModernTheme.accentGradient,
                height: 48,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: ModernTheme.primaryBlue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _pickImageFromGallery,
                    borderRadius: BorderRadius.circular(16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: ModernTheme.primaryBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Gallery',
                          style: TextStyle(
                            color: ModernTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Selected Images
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''} selected',
            style: const TextStyle(
              fontSize: 14,
              color: ModernTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: ModernTheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return _GradientButton(
      text: 'Submit Issue',
      onPressed: _isLoading ? () {} : _submitIssue,
      isLoading: _isLoading,
      icon: Icons.send,
      gradient: ModernTheme.primaryGradient,
      height: 56,
    );
  }

  // Helper method to get gradient for category
  LinearGradient _getGradientForCategory(String category) {
    switch (category) {
      case 'Public Safety':
        return ModernTheme.errorGradient;
      case 'Electricity and Power':
        return ModernTheme.accentGradient;
      case 'Water and Sewage':
        return ModernTheme.primaryGradient;
      case 'Road and Transportation':
        return ModernTheme.warningGradient;
      case 'Environmental Issues':
        return ModernTheme.successGradient;
      default:
        return ModernTheme.accentGradient;
    }
  }
}

// Supporting widgets defined locally to avoid conflicts

class _ModernCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _ModernCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final LinearGradient gradient;
  final double height;
  final double? width;

  const _GradientButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    required this.gradient,
    this.height = 48,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
