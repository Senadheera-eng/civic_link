// lib/screens/issue_map_screen.dart
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

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  List<IssueModel> _allIssues = [];
  List<IssueModel> _filteredIssues = [];
  Position? _currentLocation;
  bool _isLoading = true;

  bool _showMapView = false;

  String _selectedCategory = 'All';
  double _radiusKm = 5.0;

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
      await _getCurrentLocation();
      final issues = await _issueService.getAllIssues();

      setState(() {
        _allIssues = issues;
        _isLoading = false;
      });

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

  void _filterIssues() {
    if (_allIssues.isEmpty || _currentLocation == null) return;

    List<IssueModel> filtered = [];

    for (var issue in _allIssues) {
      double distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        issue.latitude,
        issue.longitude,
      );

      if (distance <= (_radiusKm * 1000)) {
        filtered.add(issue);
      }
    }

    if (_selectedCategory != 'All') {
      filtered =
          filtered
              .where((issue) => issue.category == _selectedCategory)
              .toList();
    }

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
  }

  void _updateMapMarkers() {
    if (_mapController == null) return;

    Set<Marker> markers = {};

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

  void _onRadiusChanged(double newRadius) {
    setState(() {
      _radiusKm = newRadius;
    });
    _filterIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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

          // View toggle
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

          // Filters
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
                DropdownButtonFormField<String>(
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
                const SizedBox(height: 16),
                Text(
                  'Search Radius: ${_radiusKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _radiusKm,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  activeColor: ModernTheme.primary,
                  onChanged: _onRadiusChanged,
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      [1, 5, 10, 25, 50].map((radius) {
                        return SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed:
                                () => _onRadiusChanged(radius.toDouble()),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              backgroundColor:
                                  _radiusKm.round() == radius
                                      ? ModernTheme.primary
                                      : Colors.white,
                              foregroundColor:
                                  _radiusKm.round() == radius
                                      ? Colors.white
                                      : Colors.black,
                              side: BorderSide(
                                color:
                                    _radiusKm.round() == radius
                                        ? ModernTheme.primary
                                        : Colors.grey.shade400,
                              ),
                              minimumSize: const Size(48, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '${radius}km',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_filteredIssues.length} issues found within ${_radiusKm.toStringAsFixed(1)}km',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, width: 1),
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
