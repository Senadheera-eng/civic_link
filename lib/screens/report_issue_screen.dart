// screens/report_issue_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../theme/simple_theme.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final IssueService _issueService = IssueService();

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
    // Initialize with default values
    _selectedCategory = IssueCategories.categories.first;
    _selectedPriority =
        IssuePriorities.priorities.length > 1
            ? IssuePriorities.priorities[1]
            : IssuePriorities.priorities.first;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check location service status first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable them in settings.',
        );
      }

      // Check permissions
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: ${e.toString()}'),
            backgroundColor: SimpleTheme.error,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                Geolocator.openAppSettings();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _issueService.pickImageFromCamera();
      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: SimpleTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _issueService.pickImageFromGallery();
      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: SimpleTheme.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be detected'),
          backgroundColor: SimpleTheme.warning,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('No Images'),
              content: const Text(
                'Are you sure you want to submit without any images?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final issueId = await _issueService.submitIssue(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        images: _selectedImages,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        address: _address,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Issue submitted successfully!'),
              ],
            ),
            backgroundColor: SimpleTheme.success,
          ),
        );

        // Navigate back to home
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit issue: $e'),
            backgroundColor: SimpleTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Status
              _buildLocationStatus(),

              const SizedBox(height: 24),

              // Issue Title
              _buildTitleField(),

              const SizedBox(height: 16),

              // Category Selection
              _buildCategoryDropdown(),

              const SizedBox(height: 16),

              // Priority Selection
              _buildPriorityDropdown(),

              const SizedBox(height: 16),

              // Description
              _buildDescriptionField(),

              const SizedBox(height: 24),

              // Image Section
              _buildImageSection(),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    return SimpleCard(
      color:
          _currentLocation != null
              ? SimpleTheme.success.withOpacity(0.1)
              : SimpleTheme.warning.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            _currentLocation != null ? Icons.location_on : Icons.location_off,
            color:
                _currentLocation != null
                    ? SimpleTheme.success
                    : SimpleTheme.warning,
          ),
          const SizedBox(width: 12),
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
                    color:
                        _currentLocation != null
                            ? SimpleTheme.success
                            : SimpleTheme.warning,
                  ),
                ),
                if (_address.isNotEmpty)
                  Text(
                    _address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SimpleTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (_isGettingLocation)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_currentLocation != null)
            IconButton(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh),
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
          'Issue Title *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SimpleTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Brief description of the issue',
            prefixIcon: Icon(Icons.title, color: SimpleTheme.primaryBlue),
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

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SimpleTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category, color: SimpleTheme.primaryBlue),
          ),
          isExpanded: true,
          items:
              IssueCategories.categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    '${IssueCategories.categoryIcons[category] ?? '📝'} $category',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SimpleTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPriority,
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.priority_high,
              color: SimpleTheme.primaryBlue,
            ),
          ),
          isExpanded: true,
          items:
              IssuePriorities.priorities.map((priority) {
                Color priorityColor;
                switch (priority.toLowerCase()) {
                  case 'low':
                    priorityColor = SimpleTheme.success;
                    break;
                  case 'medium':
                    priorityColor = SimpleTheme.warning;
                    break;
                  case 'high':
                    priorityColor = SimpleTheme.error;
                    break;
                  case 'critical':
                    priorityColor = Colors.red[800]!;
                    break;
                  default:
                    priorityColor = SimpleTheme.textSecondary;
                }

                return DropdownMenuItem<String>(
                  value: priority,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$priority (${IssuePriorities.priorityDescriptions[priority] ?? ''})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPriority = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SimpleTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SimpleTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add photos to help authorities understand the issue better',
          style: TextStyle(fontSize: 14, color: SimpleTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // Image Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Selected Images
        if (_selectedImages.isNotEmpty) ...[
          Text(
            '${_selectedImages.length} photo(s) selected',
            style: const TextStyle(
              fontSize: 14,
              color: SimpleTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: SimpleTheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
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
    return ColorfulButton(
      text: 'Submit Issue',
      onPressed: _isLoading ? null : _submitIssue,
      isLoading: _isLoading,
      icon: Icons.send,
      color: SimpleTheme.primaryBlue,
    );
  }
}
