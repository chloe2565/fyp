import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as l;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'serviceReqDetail.dart';

class ServiceRequestLocationPage extends StatefulWidget {
  const ServiceRequestLocationPage({super.key});

  @override
  State<ServiceRequestLocationPage> createState() =>
      _ServiceRequestLocationPageState();
}

class _ServiceRequestLocationPageState
    extends State<ServiceRequestLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  l.LatLng? _selectedLocation;
  final l.LatLng _initialCenter = l.LatLng(32.522, -116.98);

  // Search results dropdown
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Handles map tap events
  void _onMapTapped(TapPosition tapPosition, l.LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _searchResults = []; // Hide search results
      _searchController.text = "Loading address..."; 
      FocusScope.of(context).unfocus();
    });
    
    // Get the address
    final String address = await _getAddressFromLatLng(location);
    setState(() {
      _searchController.text = address;
    });
  }

  // Converts coordinates (LatLng) into a human-readable address
  Future<String> _getAddressFromLatLng(l.LatLng location) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1');

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.fyp'},
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body);
        if (results != null && results['display_name'] != null) {
          return results['display_name'];
        }
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
  }

  // Gets user's current location and moves the map
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, cannot request permissions.',
          ),
        ),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      l.LatLng currentLatLng = l.LatLng(position.latitude, position.longitude);

      _mapController.move(currentLatLng, 15.0);
      setState(() {
        _selectedLocation = currentLatLng;
        _searchResults = []; // Hide search results
        _searchController.text = "Loading address...";
        FocusScope.of(context).unfocus();
      });
      
      // Get the address
      final String address = await _getAddressFromLatLng(currentLatLng);
      setState(() {
        _searchController.text = address;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Called on every keystroke in the search bar
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      if (query.isNotEmpty) {
        _searchLocation(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  // Search for a location using Nominatim API
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.fyp'},
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        setState(() {
          _searchResults = results.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print("Error searching location: $e");
    }
  }

  // Search and select the top result then move the map
  Future<void> _searchAndSelectTopResult(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.fyp'},
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        if (results.isNotEmpty) {
          // Found a result
          final result = results[0];
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          final newLocation = l.LatLng(lat, lon);

          // Move map and update marker
          _mapController.move(newLocation, 15.0);
          setState(() {
            _selectedLocation = newLocation;
            _searchController.text = result['display_name'];
            _searchResults = []; // Hide dropdown
          });
          FocusScope.of(context).unfocus(); // Hide keyboard
        } else {
          // No result found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found.')),
          );
        }
      }
    } catch (e) {
      print("Error searching location: $e");
    }
  }

  // Builds the list of markers to display on the map
  List<Marker> _buildMarkers() {
    if (_selectedLocation == null) {
      return []; 
    }
    return [
      Marker(
        width: 40.0,
        height: 40.0,
        point: _selectedLocation!,
        child: Icon(
          Icons.location_on,
          color: Theme.of(context).primaryColor,
          size: 40,
        ),
      ),
    ];
  }

  // Navigates to the details page
  void _navigateToNext() {
    if (_selectedLocation == null) return;

    final String locationData = _searchController.text.isNotEmpty
        ? _searchController.text
        : '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ServiceRequestDetailsPage(selectedLocation: locationData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Electric Service Booking',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0, // top & bottom
                  horizontal: 16.0, // left & right
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        style: Theme.of(context).textTheme.bodySmall,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search Location',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: _getCurrentLocation,
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.my_location,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onFieldSubmitted: _searchAndSelectTopResult,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 17.0,
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 15.0,
                      onTap: _onMapTapped,
                    ),
                    children: [
                      // Actual map
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.fyp',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                ),
              ),
              // Next Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ElevatedButton(
                    onPressed: _selectedLocation == null
                        ? null
                        : _navigateToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLocation == null
                          ? const Color(0xFFE0E0E0)
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: _selectedLocation == null
                          ? Colors.grey
                          : Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 70, // Adjust this to position below your search bar
              left: 16.0,
              right: 16.0,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        title: Text(result['display_name'] ?? 'Unknown location'),
                        dense: true,
                        onTap: () {
                          final lat = double.parse(result['lat']);
                          final lon = double.parse(result['lon']);
                          final newLocation = l.LatLng(lat, lon);

                          _mapController.move(newLocation, 15.0);
                          setState(() {
                            _selectedLocation = newLocation;
                            _searchController.text = result['display_name'];
                            _searchResults = []; // Hide list
                          });
                          FocusScope.of(context).unfocus(); // Hide keyboard
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}