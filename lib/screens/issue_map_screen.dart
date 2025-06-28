// screens/issue_map_screen.dart (ENHANCED WITH GOOGLE MAPS LOCATION PICKER)
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';
import 'issue_detail_screen.dart';

class IssueMapScreen extends StatefulWidget {
  const IssueMapScreen({Key? key}) : super(key: key);

  @override
  State<IssueMapScreen> createState() => _IssueMapScreenState();
}

class _IssueMapScreenState extends State<IssueMapScreen>
    with TickerProviderStateMixin {
  final IssueService _issueService = IssueService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  List<IssueModel> _allIssues = [];
  List<IssueModel> _nearbyIssues = [];
  Position? _currentLocation;
  LatLng? _selectedLocation; // New: User selected location
  bool _isLoading = true;
  bool _isGettingLocation = false;

  // UI State
  bool _showMapView = false; // Toggle between list and map view
  String _locationMode = 'current'; // 'current' or 'selected'

  // Filters
  String _selectedCategory = 'All';
  double _radiusKm = 5.0;
  String _selectedLocationFilter = 'nearby';

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

  @override
  void dispose() {
    _fadeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load user's current location
      await _getCurrentLocation();

      // Load all issues
      final issues = await _issueService.getAllIssues();

      setState(() {
        _allIssues = issues;
        _isLoading = false;
      });

      // Filter nearby issues and update map markers
      _filterNearbyIssues();
      _updateMapMarkers();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading issues: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = position;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      _showErrorSnackBar('Location error: $e');
    }
  }

  void _filterNearbyIssues() {
    LatLng? centerLocation;

    // Determine center location based on mode
    if (_locationMode == 'selected' && _selectedLocation != null) {
      centerLocation = _selectedLocation;
    } else if (_locationMode == 'current' && _currentLocation != null) {
      centerLocation = LatLng(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
    }

    if (centerLocation == null) return;

    List<IssueModel> filteredIssues = [];

    switch (_selectedLocationFilter) {
      case 'nearby':
        // Filter by radius
        for (var issue in _allIssues) {
          double distanceInMeters = Geolocator.distanceBetween(
            centerLocation.latitude,
            centerLocation.longitude,
            issue.latitude,
            issue.longitude,
          );

          if (distanceInMeters <= (_radiusKm * 1000)) {
            filteredIssues.add(issue);
          }
        }
        break;
      case 'city':
        // Filter by city (20km radius)
        for (var issue in _allIssues) {
          double distanceInMeters = Geolocator.distanceBetween(
            centerLocation.latitude,
            centerLocation.longitude,
            issue.latitude,
            issue.longitude,
          );
          if (distanceInMeters <= 20000) {
            filteredIssues.add(issue);
          }
        }
        break;
      case 'all':
        filteredIssues = _allIssues;
        break;
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filteredIssues =
          filteredIssues
              .where((issue) => issue.category == _selectedCategory)
              .toList();
    }

    // Sort by distance (nearest first)
    filteredIssues.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
        centerLocation!.latitude,
        centerLocation.longitude,
        a.latitude,
        a.longitude,
      );
      double distanceB = Geolocator.distanceBetween(
        centerLocation.latitude,
        centerLocation.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      _nearbyIssues = filteredIssues;
    });
  }

  void _updateMapMarkers() {
    if (_mapController == null) return;

    Set<Marker> markers = {};

    // Add issue markers
    for (var issue in _nearbyIssues) {
      markers.add(
        Marker(
          markerId: MarkerId(issue.id),
          position: LatLng(issue.latitude, issue.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(issue.status),
          ),
          infoWindow: InfoWindow(
            title: issue.title,
            snippet: issue.category,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IssueDetailScreen(issue: issue),
                ),
              );
            },
          ),
        ),
      );
    }

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add selected location marker
    if (_selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  double _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BitmapDescriptor.hueOrange;
      case 'in_progress':
        return BitmapDescriptor.hueYellow;
      case 'resolved':
        return BitmapDescriptor.hueGreen;
      case 'rejected':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _locationMode = 'selected';
    });

    _filterNearbyIssues();
    _updateMapMarkers();

    _showSuccessSnackBar('Location selected! Showing nearby issues.');
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          14.0,
        ),
      );

      setState(() {
        _locationMode = 'current';
        _selectedLocation = null;
      });

      _filterNearbyIssues();
      _updateMapMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ModernTheme.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildModernHeader(),
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
                    child: Column(
                      children: [
                        _buildLocationStatus(),
                        _buildViewToggle(),
                        if (!_showMapView) _buildFilters(),
                        Expanded(
                          child:
                              _showMapView
                                  ? _buildMapView()
                                  : _buildIssuesList(),
                        ),
                      ],
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

  Widget _buildModernHeader() {
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
                  'Issue Map',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Explore nearby issues',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.white),
              onPressed: _moveToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    String statusText;
    String subtitleText;
    Color statusColor;
    IconData statusIcon;

    if (_locationMode == 'selected') {
      statusText = 'Custom Location Selected';
      subtitleText = 'Showing issues around selected location';
      statusColor = ModernTheme.accent;
      statusIcon = Icons.location_on;
    } else if (_currentLocation != null) {
      statusText = 'Current Location';
      subtitleText = 'Showing issues within ${_radiusKm}km radius';
      statusColor = ModernTheme.success;
      statusIcon = Icons.location_on;
    } else {
      statusText = 'Getting Location...';
      subtitleText = 'Enable location to see nearby issues';
      statusColor = ModernTheme.warning;
      statusIcon = Icons.location_searching;
    }

    return Container(
      margin: const EdgeInsets.all(24),
      child: ModernCard(
        color: statusColor.withOpacity(0.1),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ModernTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_isGettingLocation)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showMapView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: !_showMapView ? ModernTheme.primaryGradient : null,
                  color: !_showMapView ? null : ModernTheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  border: Border.all(
                    color:
                        !_showMapView
                            ? Colors.transparent
                            : ModernTheme.textTertiary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      color:
                          !_showMapView
                              ? Colors.white
                              : ModernTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'List View',
                      style: TextStyle(
                        color:
                            !_showMapView
                                ? Colors.white
                                : ModernTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showMapView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _showMapView ? ModernTheme.primaryGradient : null,
                  color: _showMapView ? null : ModernTheme.surface,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color:
                        _showMapView
                            ? Colors.transparent
                            : ModernTheme.textTertiary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      color:
                          _showMapView
                              ? Colors.white
                              : ModernTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Map View',
                      style: TextStyle(
                        color:
                            _showMapView
                                ? Colors.white
                                : ModernTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentLocation == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading map...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Map Instructions
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: ModernTheme.accentGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap anywhere on the map to select a location and find nearby issues!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Radius Selector for Map View
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ModernTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ModernTheme.textTertiary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Radius: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ModernTheme.textSecondary,
                ),
              ),
              Text(
                '${_radiusKm.toStringAsFixed(1)}km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.primaryBlue,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 0.5,
                  max: 50.0,
                  divisions: 50,
                  activeColor: ModernTheme.primaryBlue,
                  onChanged: (value) {
                    setState(() => _radiusKm = value);
                    _filterNearbyIssues();
                    _updateMapMarkers();
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Google Maps Widget
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: ModernTheme.cardShadow,
            ),
            clipBehavior: Clip.hardEdge,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _updateMapMarkers();
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                ),
                zoom: 14.0,
              ),
              markers: _markers,
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),

        // Issues count
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: ModernTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_nearbyIssues.length} Issues Found',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Location Filter
          const Text(
            'Location Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLocationFilterChip('Nearby', 'nearby', Icons.my_location),
              const SizedBox(width: 8),
              _buildLocationFilterChip('City', 'city', Icons.location_city),
              const SizedBox(width: 8),
              _buildLocationFilterChip('All', 'all', Icons.public),
            ],
          ),

          // Radius Slider (only show for nearby)
          if (_selectedLocationFilter == 'nearby') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Radius: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ModernTheme.textSecondary,
                  ),
                ),
                Text(
                  '${_radiusKm.toStringAsFixed(1)}km',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.primaryBlue,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 0.5,
                    max: 50.0,
                    divisions: 50,
                    activeColor: ModernTheme.primaryBlue,
                    onChanged: (value) {
                      setState(() => _radiusKm = value);
                      _filterNearbyIssues();
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Category Filter
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ModernTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLocationFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedLocationFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLocationFilter = value);
        _filterNearbyIssues();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? ModernTheme.primaryGradient : null,
          color: isSelected ? null : ModernTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : ModernTheme.textTertiary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : ModernTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : ModernTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = [
      {'name': 'All', 'icon': Icons.apps},
      {'name': 'Road & Transportation', 'icon': Icons.construction},
      {'name': 'Water & Sewerage', 'icon': Icons.water_drop},
      {'name': 'Electricity', 'icon': Icons.electrical_services},
      {'name': 'Public Safety', 'icon': Icons.security},
      {'name': 'Waste Management', 'icon': Icons.delete},
      {'name': 'Parks & Recreation', 'icon': Icons.park},
      {'name': 'Street Lighting', 'icon': Icons.lightbulb},
      {'name': 'Public Buildings', 'icon': Icons.business},
      {'name': 'Traffic Management', 'icon': Icons.traffic},
      {'name': 'Environmental Issues', 'icon': Icons.eco},
    ];

    return Container(
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
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: ModernTheme.primaryBlue),
          style: const TextStyle(
            fontSize: 16,
            color: ModernTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: ModernTheme.surface,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 300,
          items:
              categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['name'] as String,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                _selectedCategory == category['name']
                                    ? ModernTheme.primaryBlue.withOpacity(0.1)
                                    : ModernTheme.textTertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            size: 18,
                            color:
                                _selectedCategory == category['name']
                                    ? ModernTheme.primaryBlue
                                    : ModernTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category['name'] as String,
                            style: TextStyle(
                              color:
                                  _selectedCategory == category['name']
                                      ? ModernTheme.primaryBlue
                                      : ModernTheme.textPrimary,
                              fontWeight:
                                  _selectedCategory == category['name']
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedCategory == category['name'])
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: ModernTheme.primaryBlue,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedCategory = newValue);
              _filterNearbyIssues();
            }
          },
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading nearby issues...'),
          ],
        ),
      );
    }

    LatLng? centerLocation;
    if (_locationMode == 'selected' && _selectedLocation != null) {
      centerLocation = _selectedLocation;
    } else if (_locationMode == 'current' && _currentLocation != null) {
      centerLocation = LatLng(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
    }

    if (centerLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ModernTheme.warningGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ModernTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enable location access or select a location on the map',
              style: TextStyle(fontSize: 16, color: ModernTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Enable Location',
              onPressed: _getCurrentLocation,
              icon: Icons.location_on,
              width: 180,
              height: 44,
            ),
          ],
        ),
      );
    }

    if (_nearbyIssues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ModernTheme.accentGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Issues Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ModernTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedLocationFilter == 'nearby'
                  ? 'No issues found within ${_radiusKm.toStringAsFixed(1)}km radius'
                  : 'No issues found for selected filters',
              style: const TextStyle(
                fontSize: 16,
                color: ModernTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_nearbyIssues.length} Issues Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _locationMode == 'selected'
                    ? 'At selected location'
                    : _selectedLocationFilter == 'nearby'
                    ? 'Within ${_radiusKm.toStringAsFixed(1)}km'
                    : _selectedLocationFilter == 'city'
                    ? 'In your city'
                    : 'All locations',
                style: const TextStyle(
                  fontSize: 12,
                  color: ModernTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Issues list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _nearbyIssues.length,
            itemBuilder: (context, index) {
              final issue = _nearbyIssues[index];
              final distance = Geolocator.distanceBetween(
                centerLocation!.latitude,
                centerLocation.longitude,
                issue.latitude,
                issue.longitude,
              );

              return _buildIssueCard(issue, distance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIssueCard(IssueModel issue, double distanceInMeters) {
    final statusColor = _getStatusColor(issue.status);
    final priorityColor = _getPriorityColor(issue.priority);
    final distanceText =
        distanceInMeters < 1000
            ? '${distanceInMeters.toInt()}m away'
            : '${(distanceInMeters / 1000).toStringAsFixed(1)}km away';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailScreen(issue: issue),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ModernTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(issue.category),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ModernTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: ModernTheme.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distanceText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ModernTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ModernStatusChip(
                  text: _getStatusText(issue.status),
                  color: statusColor,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              issue.description,
              style: const TextStyle(
                fontSize: 14,
                color: ModernTheme.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.category.split(' ').first,
                    style: const TextStyle(
                      fontSize: 10,
                      color: ModernTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.priority,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'By ${issue.userName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ModernTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getTimeAgo(issue.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ModernTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ModernTheme.warning;
      case 'in_progress':
        return ModernTheme.accent;
      case 'resolved':
        return ModernTheme.success;
      case 'rejected':
        return ModernTheme.error;
      default:
        return ModernTheme.textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return ModernTheme.success;
      case 'medium':
        return ModernTheme.warning;
      case 'high':
        return ModernTheme.error;
      case 'critical':
        return const Color(0xFFDC2626);
      default:
        return ModernTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Road & Transportation':
        return Icons.construction;
      case 'Water & Sewerage':
        return Icons.water_drop;
      case 'Electricity':
        return Icons.electrical_services;
      case 'Public Safety':
        return Icons.security;
      case 'Waste Management':
        return Icons.delete;
      case 'Parks & Recreation':
        return Icons.park;
      case 'Street Lighting':
        return Icons.lightbulb;
      case 'Public Buildings':
        return Icons.business;
      case 'Traffic Management':
        return Icons.traffic;
      case 'Environmental Issues':
        return Icons.eco;
      default:
        return Icons.report_problem;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
}
