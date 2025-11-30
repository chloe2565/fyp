import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../controller/serviceRequest.dart';
import 'serviceReqDetail.dart';

class ServiceRequestLocationScreen extends StatefulWidget {
  final String serviceID;
  final String serviceName;

  const ServiceRequestLocationScreen({
    super.key,
    required this.serviceID,
    required this.serviceName,
  });

  @override
  State<ServiceRequestLocationScreen> createState() =>
      ServiceRequestLocationScreenState();
}

class ServiceRequestLocationScreenState
    extends State<ServiceRequestLocationScreen> {
  final TextEditingController searchController = TextEditingController();
  GoogleMapController? googleMapController;

  LatLng? selectedLocation;
  final LatLng initialCenter = const LatLng(5.4164, 100.3327); // GeorgeTown

  // Search results dropdown
  Timer? debounce;
  List<Map<String, dynamic>> searchResults = [];

  @override
  void dispose() {
    searchController.dispose();
    googleMapController?.dispose();
    debounce?.cancel();
    super.dispose();
  }

  // Handles map tap events
  void onMapTapped(LatLng location) async {
    setState(() {
      selectedLocation = location;
      searchResults = []; // Hide search results
      searchController.text = "Loading address...";
      FocusScope.of(context).unfocus();
    });

    // Get the address
    final String address = await getAddressFromLatLng(location);
    setState(() {
      searchController.text = address;
    });
  }

  // Converts coordinates into address
  Future<String> getAddressFromLatLng(LatLng location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.fyp'},
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body);
        if (results != null && results['display_name'] != null) {
          return results['display_name'];
        } else {
          print("Nominatim response missing 'display_name': $results");
        }
      } else {
        print("Nominatim request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return 'Could not get address. Tap map again or search.';
  }

  // Gets user's current location and moves the map
  Future<void> getCurrentLocation() async {
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
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      // Move to current location
      googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15.0),
      );

      setState(() {
        selectedLocation = currentLatLng;
        searchResults = []; // Hide search results
        searchController.text = "Loading address...";
        FocusScope.of(context).unfocus();
      });

      // Get the address
      final String address = await getAddressFromLatLng(currentLatLng);
      setState(() {
        searchController.text = address;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Called on every keystroke in the search bar
  void onSearchChanged(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 750), () {
      if (query.isNotEmpty) {
        searchLocation(query);
      } else {
        setState(() {
          searchResults = [];
        });
      }
    });
  }

  // Search for a location using Nominatim API
  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;
    final encodedQuery = Uri.encodeComponent(query);

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$encodedQuery'
      '&format=json'
      '&addressdetails=1'
      '&limit=10',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.fyp'},
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        setState(() {
          searchResults = results.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print("Error searching location: $e");
    }
  }

  // Search and select the top result then move the map
  Future<void> searchAndSelectTopResult(String query) async {
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
          final newLocation = LatLng(lat, lon);

          // Move map and update marker
          googleMapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newLocation, 15.0),
          );

          setState(() {
            selectedLocation = newLocation;
            searchController.text = result['display_name'];
            searchResults = []; // Hide dropdown
          });
          FocusScope.of(context).unfocus(); // Hide keyboard
        } else {
          // No result found
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Location not found.')));
        }
      }
    } catch (e) {
      print("Error searching location: $e");
    }
  }

  // Build markers for Google Maps
  Set<Marker> buildMarkers() {
    if (selectedLocation == null) {
      return {};
    }
    return {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: selectedLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Selected Location'),
      ),
    };
  }

  // Navigates to the details page
  void navigateToNext() {
    if (selectedLocation == null) return;

    if (selectedLocation == null ||
        searchController.text.isEmpty ||
        searchController.text == "Loading address..." ||
        searchController.text ==
            'Could not get address. Tap map again or search.') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a location or wait for address to load.',
          ),
        ),
      );
      return;
    }

    final String locationText = searchController.text;
    final LatLng locationCoord = selectedLocation!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          final controller = ServiceRequestController();
          controller.initialize().then((_) {});
          return ChangeNotifierProvider.value(
            value: controller,
            child: ServiceRequestDetailsScreen(
              selectedLocationText: locationText,
              selectedLocationCoord: locationCoord,
              serviceID: widget.serviceID,
              serviceName: widget.serviceName,
            ),
          );
        },
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
        title: Text(
          '${widget.serviceName} Service Booking',
          style: const TextStyle(
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
                  vertical: 10.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: searchController,
                        style: Theme.of(context).textTheme.bodySmall,
                        onChanged: onSearchChanged,
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
                            onTap: getCurrentLocation,
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
                        onFieldSubmitted: searchAndSelectTopResult,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        googleMapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: initialCenter,
                        zoom: 15.0,
                      ),
                      onTap: onMapTapped,
                      markers: buildMarkers(),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapType: MapType.normal,
                    ),
                  ),
                ),
              ),
              // Next Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ElevatedButton(
                    onPressed: selectedLocation == null ? null : navigateToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedLocation == null
                          ? const Color(0xFFE0E0E0)
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: selectedLocation == null
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
          if (searchResults.isNotEmpty)
            Positioned(
              top: 70,
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
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final result = searchResults[index];
                      return ListTile(
                        title: Text(
                          result['display_name'] ?? 'Unknown location',
                        ),
                        dense: true,
                        onTap: () {
                          final lat = double.parse(result['lat']);
                          final lon = double.parse(result['lon']);
                          final newLocation = LatLng(lat, lon);

                          googleMapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(newLocation, 15.0),
                          );

                          setState(() {
                            selectedLocation = newLocation;
                            searchController.text = result['display_name'];
                            searchResults = []; // Hide list
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
