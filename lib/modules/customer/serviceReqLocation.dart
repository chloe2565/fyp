import 'package:flutter/material.dart';

import 'serviceReqDetail.dart';

class ServiceRequestLocationPage extends StatefulWidget {
  const ServiceRequestLocationPage({super.key});

  @override
  State<ServiceRequestLocationPage> createState() =>
      _ServiceRequestLocationPageeState();
}

class _ServiceRequestLocationPageeState
    extends State<ServiceRequestLocationPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Electric Service Booking', // Example title from image
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Location',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(
                          6,
                        ), // Adjust margin for visual padding
                        decoration: BoxDecoration(
                          color: Colors
                              .grey
                              .shade200, // Light grey background for the icon
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFFFF7643),
                          size: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFFF7643).withOpacity(0.5),
                          width: 1.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onTap: () {
                      // TODO: Implement search functionality or navigate to a search page
                      print('Search field tapped!');
                    },
                    onFieldSubmitted: (value) {
                      // TODO: Implement search on submit
                      print('Search submitted: $value');
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade200, // Placeholder for the map
              child: Stack(
                children: [
                  // This is where an actual map widget would go (e.g., GoogleMap)
                  Center(
                    child: Image.asset(
                      'assets/images/map_placeholder.png', // Placeholder image of a map
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            'Map Placeholder',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Red pin at a central location (example)
                  const Positioned(
                    left: 100, // Example position
                    top: 150, // Example position
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                  const Positioned(
                    right: 80, // Example position
                    bottom: 120, // Example position
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ),
          ),
          // Next Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                // You would get the actual selected location here
                final String selectedLocation =
                    _searchController.text.isNotEmpty
                    ? _searchController.text
                    : '18, Jalan Lembah Permai, Tanjung Bungah'; // Default or from map

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceRequestDetailsPage(
                      selectedLocation: selectedLocation,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFE0E0E0,
                ), // Grey color from image
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(
                  double.infinity,
                  50,
                ), // Make button full width
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey, // Text color from image
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
