// screens/issue_map_screen.dart (FIXED VERSION - Crash Issues Resolved)
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
  LatLng? _selectedLocation;
  bool _isLoading = true;
  bool _isGettingLocation = false;
  bool _isDisposed = false; // ADDED: Track disposal state

  // UI State
  bool _showMapView = false;
  String _locationMode = 'current';

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
    _isDisposed = true; // ADDED: Mark as disposed
    _fadeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // FIXED: Added safety checks for mounted state
  void _safeSetState(VoidCallback callback) {
    if (mounted && !_isDisposed) {
      setState(callback);
    }
  }

  Future<void> _loadData() async {
    _safeSetState(() => _isLoading = true);

    try {
      // Load user's current location
      await _getCurrentLocation();

      // Check if still mounted after async operation
      if (!mounted || _isDisposed) return;

      // Load all issues
      final issues = await _issueService.getAllIssues();

      // Check if still mounted after async operation
      if (!mounted || _isDisposed) return;

      _safeSetState(() {
        _allIssues = issues;
        _isLoading = false;
      });

      // Filter nearby issues and update map markers
      await _filterNearbyIssues();
      await _updateMapMarkers();
    } catch (e) {
      if (mounted && !_isDisposed) {
        _safeSetState(() => _isLoading = false);
        _showErrorSnackBar('Error loading issues: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    _safeSetState(() => _isGettingLocation = true);

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
        timeLimit: const Duration(
          seconds: 10,
        ), // ADDED: Timeout to prevent hanging
      );

      // Check if still mounted after async operation
      if (!mounted || _isDisposed) return;

      _safeSetState(() {
        _currentLocation = position;
        _isGettingLocation = false;
      });
    } catch (e) {
      if (mounted && !_isDisposed) {
        _safeSetState(() => _isGettingLocation = false);
        _showErrorSnackBar('Location error: $e');
      }
    }
  }

  // FIXED: Made async and added safety checks
  Future<void> _filterNearbyIssues() async {
    if (_allIssues.isEmpty || (!mounted || _isDisposed)) return;

    LatLng? centerLocation;

    if (_locationMode == 'current' && _currentLocation != null) {
      centerLocation = LatLng(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
    } else if (_locationMode == 'selected' && _selectedLocation != null) {
      centerLocation = _selectedLocation;
    }

    if (centerLocation == null) return;

    List<IssueModel> filteredIssues = [];

    for (var issue in _allIssues) {
      try {
        double distance = Geolocator.distanceBetween(
          centerLocation.latitude,
          centerLocation.longitude,
          issue.latitude,
          issue.longitude,
        );

        if (distance <= (_radiusKm * 1000)) {
          filteredIssues.add(issue);
        }
      } catch (e) {
        print('Skipping issue with invalid coordinates: ${issue.id}');
        continue;
      }
    }

    // Filter by category if not 'All'
    if (_selectedCategory != 'All') {
      filteredIssues =
          filteredIssues
              .where((issue) => issue.category == _selectedCategory)
              .toList();
    }

    // Sort by distance (nearest first)
    filteredIssues.sort((a, b) {
      try {
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
      } catch (e) {
        return 0; // Keep original order if comparison fails
      }
    });

    if (mounted && !_isDisposed) {
      _safeSetState(() {
        _nearbyIssues = filteredIssues;
      });
    }
  }

  // FIXED: Made async and added safety checks
  Future<void> _updateMapMarkers() async {
    if (_mapController == null || (!mounted || _isDisposed)) return;

    try {
      Set<Marker> markers = {};

      // Add issue markers
      for (var issue in _nearbyIssues) {
        try {
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
                  if (mounted && !_isDisposed) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IssueDetailScreen(issue: issue),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        } catch (e) {
          print('Error creating marker for issue ${issue.id}: $e');
          continue;
        }
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
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
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

      if (mounted && !_isDisposed) {
        _safeSetState(() {
          _markers = markers;
        });
      }
    } catch (e) {
      print('Error updating map markers: $e');
    }
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

  // FIXED: Added safety checks
  void _onMapTap(LatLng location) {
    if (!mounted || _isDisposed) return;

    _safeSetState(() {
      _selectedLocation = location;
      _locationMode = 'selected';
    });

    _filterNearbyIssues();
    _updateMapMarkers();

    _showSuccessSnackBar('Location selected! Showing nearby issues.');
  }

  // FIXED: Added safety checks
  void _moveToCurrentLocation() {
    if (_currentLocation != null &&
        _mapController != null &&
        mounted &&
        !_isDisposed) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          14.0,
        ),
      );

      _safeSetState(() {
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
            child: _showMapView ? _buildMapView() : _buildListView(),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        _buildHeader(),
        _buildViewToggle(),
        _buildFilters(),
        _buildIssuesList(),
      ],
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
        _buildHeader(),
        _buildViewToggle(),
        _buildFilters(),

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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
                if (mounted && !_isDisposed) {
                  _mapController = controller;
                  _updateMapMarkers();
                }
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

        // Issues count and location button
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: ModernTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_nearbyIssues.length} Issues Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FloatingActionButton.small(
                onPressed: _moveToCurrentLocation,
                backgroundColor: ModernTheme.primary,
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Issue Map',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernTheme.textTertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _safeSetState(() => _showMapView = false),
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
              onTap: () => _safeSetState(() => _showMapView = true),
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

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: ModernTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ModernTheme.textTertiary.withOpacity(0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items:
                      [
                            'All',
                            'Public Safety',
                            'Electricity and Power',
                            'Water and Sewage',
                            'Road and Transportation',
                            'Environmental Issues',
                          ]
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null && mounted && !_isDisposed) {
                      _safeSetState(() => _selectedCategory = value);
                      _filterNearbyIssues();
                      _updateMapMarkers();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ModernTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_radiusKm.toInt()}km',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesList() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_nearbyIssues.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No issues found nearby',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try increasing the search radius or changing location',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _nearbyIssues.length,
        itemBuilder: (context, index) {
          final issue = _nearbyIssues[index];
          return _buildIssueCard(issue);
        },
      ),
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernTheme.cardShadow,
      ),
      child: ListTile(
        onTap: () {
          if (mounted && !_isDisposed) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IssueDetailScreen(issue: issue),
              ),
            );
          }
        },
        title: Text(
          issue.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(issue.category),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(issue.status),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            issue.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: ModernTheme.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
