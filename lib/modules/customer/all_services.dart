// lib/pages/all_services_screen.dart

import 'package:flutter/material.dart';
import 'db_data.dart'; // <-- Import your central data source
import 'service_detail.dart';

class AllServicesScreen extends StatelessWidget {
  const AllServicesScreen({super.key});

  // The local static list is now REMOVED.
  // We will use 'allAppServices' from db_data.dart instead.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Services', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search bar
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Search here..',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(icon: const Icon(Icons.tune, color: Colors.orange), onPressed: () {}),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 24),
            // The list now uses our central data from db_data.dart
            Expanded(
              child: ListView.builder(
                // Use the length of the imported 'allAppServices' list
                itemCount: allAppServices.length,
                itemBuilder: (context, index) {
                  final service = allAppServices[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to the detail page, passing the full service object
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceDetailPage(service: service),
                          ),
                        );
                      },
                      child: ServiceListItemCard(
                        title: service.title,
                        price: service.price,
                        icon: service.icon,
                        color: service.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The ServiceListItemCard widget remains exactly the same.
class ServiceListItemCard extends StatelessWidget {
  // ... (No changes here)
  final String title;
  final String price;
  final IconData icon;
  final Color color;

  const ServiceListItemCard({
    required this.title,
    required this.price,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // ... UI code for the card
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}