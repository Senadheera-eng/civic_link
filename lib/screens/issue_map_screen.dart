// lib/screens/issue_map_screen.dart (SIMPLE WORKING VERSION)
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/issue_service.dart';
import '../models/issue_model.dart';
import '../theme/modern_theme.dart';

class IssueMapScreen extends StatefulWidget {
  const IssueMapScreen({Key? key}) : super(key: key);

  @override
  State<IssueMapScreen> createState() => _IssueMapScreenState();
}

class _IssueMapScreenState extends State<IssueMapScreen> {
  final IssueService _issueService = IssueService();

  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  List<IssueModel> _allIssues = [];
  List<IssueModel> _filteredIssues = [];
  Position? _currentLocation;
  bool _isLoading = true;

  // UI State
  bool _showMapView = false;

  // Filters
  String _selectedCategory = 'All';
  double _radiusKm = 5.0; // THIS IS THE ADJUSTABLE RADIUS

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get current location
      await _getCurrentLocation();

      // Load all issues
      final issues = await _issueService.getAllIssues();

      setState(() {
        _allIssues = issues;
        _isLoading = false;
      });

      // Filter issues based on radius
      _filterIssues();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Error loading data: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      _showErrorMessage('Location error: $e');
    }
  }

  // MAIN FUNCTION: Filter issues based on radius
  void _filterIssues() {
    if (_allIssues.isEmpty || _currentLocation == null) return;

    List<IssueModel> filtered = [];

    for (var issue in _allIssues) {
      // Calculate distance from current location to issue
      double distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        issue.latitude,
        issue.longitude,
      );

      // Convert radius to meters and check if issue is within radius
      if (distance <= (_radiusKm * 1000)) {
        filtered.add(issue);
      }
    }

    // Filter by category if not 'All'
    if (_selectedCategory != 'All') {
      filtered =
          filtered
              .where((issue) => issue.category == _selectedCategory)
              .toList();
    }

    // Sort by distance (nearest first)
    filtered.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        a.latitude,
        a.longitude,
      );
      double distanceB = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    setState(() {
      _filteredIssues = filtered;
    });

    _updateMapMarkers();
    print('🔍 Filtered to ${filtered.length} issues within ${_radiusKm}km');
  }

  void _updateMapMarkers() {
    if (_mapController == null) return;

    Set<Marker> markers = {};

    // Add markers for filtered issues
    for (var issue in _filteredIssues) {
      markers.add(
        Marker(
          markerId: MarkerId(issue.id),
          position: LatLng(issue.latitude, issue.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(issue.status),
          ),
          infoWindow: InfoWindow(title: issue.title, snippet: issue.category),
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

  // RADIUS CHANGE HANDLER
  void _onRadiusChanged(double newRadius) {
    setState(() {
      _radiusKm = newRadius;
    });
    _filterIssues(); // Re-filter when radius changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ModernTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
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
            ),
          ),

          // View Toggle
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showMapView = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            !_showMapView
                                ? ModernTheme.primary
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            color: !_showMapView ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'List View',
                            style: TextStyle(
                              color: !_showMapView ? Colors.white : Colors.grey,
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
                        color:
                            _showMapView
                                ? ModernTheme.primary
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            color: _showMapView ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Map View',
                            style: TextStyle(
                              color: _showMapView ? Colors.white : Colors.grey,
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
          ),

          // Filters Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
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
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                            _filterIssues();
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // RADIUS CONTROL - THIS IS THE MAIN FEATURE!
                Text(
                  'Search Radius: ${_radiusKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Radius Slider
                Slider(
                  value: _radiusKm,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  activeColor: ModernTheme.primary,
                  onChanged: _onRadiusChanged, // This updates the radius!
                ),

                // Quick radius buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      [1, 5, 10, 25, 50].map((radius) {
                        return ElevatedButton(
                          onPressed: () => _onRadiusChanged(radius.toDouble()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _radiusKm.round() == radius
                                    ? ModernTheme.primary
                                    : Colors.grey[300],
                            foregroundColor:
                                _radiusKm.round() == radius
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          child: Text('${radius}km'),
                        );
                      }).toList(),
                ),

                // Results Count
                const SizedBox(height: 12),
                Text(
                  '${_filteredIssues.length} issues found within ${_radiusKm.toStringAsFixed(1)}km',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _showMapView
                    ? _buildMapView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentLocation == null) {
      return const Center(child: Text('Getting your location...'));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
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
          zoom: 13.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }

  Widget _buildListView() {
    if (_filteredIssues.isEmpty) {
      return const Center(child: Text('No issues found in this area'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredIssues.length,
      itemBuilder: (context, index) {
        final issue = _filteredIssues[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      issue.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColorForCard(issue.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      issue.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                issue.category,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                issue.description.length > 100
                    ? '${issue.description.substring(0, 100)}...'
                    : issue.description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColorForCard(String status) {
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
