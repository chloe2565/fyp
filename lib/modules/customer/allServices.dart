import 'package:flutter/material.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import 'serviceDetail.dart';
import '../../shared/helper.dart';

class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => AllServicesScreenState();
}

class AllServicesScreenState extends State<AllServicesScreen> {
  final TextEditingController searchController = TextEditingController();
  late Future<List<ServiceModel>> servicesFuture;
  List<ServiceModel> allServices = [];
  List<ServiceModel> displayedServices = [];
  bool isLoading = true;

  double minPrice = 0;
  double maxPrice = 100; 

  @override
  void initState() {
    super.initState();
    servicesFuture = ServiceController().getAllServices();
    loadServices();
    searchController.addListener(filterServices);
  }

  Future<void> loadServices() async {
    try {
      allServices = await servicesFuture;
      displayedServices = allServices;
    } catch (e) {
      // Handle error (e.g., show snackbar)
    }
    setState(() {
      isLoading = false;
    });
  }

  void filterServices() {
    final query = searchController.text.toLowerCase();
    setState(() {
      displayedServices = allServices.where((service) {
        final matchesName = service.serviceName.toLowerCase().contains(query);
        final matchesPrice = service.servicePrice != null &&
            service.servicePrice! >= minPrice &&
            service.servicePrice! <= maxPrice;
        return matchesName && matchesPrice;
      }).toList();
    });
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: minPrice,
                min: 0,
                max: 100,
                label: 'Min: $minPrice',
                onChanged: (value) {
                  setState(() {
                    minPrice = value;
                  });
                },
              ),
              Slider(
                value: maxPrice,
                min: 0,
                max: 100,
                label: 'Max: $maxPrice',
                onChanged: (value) {
                  setState(() {
                    maxPrice = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                filterServices();
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Services',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search bar with filter
            TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search here..',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.orange),
                  onPressed: showFilterDialog,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: displayedServices.length,
                      itemBuilder: (context, index) {
                        final service = displayedServices[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ServiceDetailScreen(service: service),
                                ),
                              );
                            },
                            child: ServiceListItemCard(
                              title: service.serviceName,
                              price: service.servicePrice != null
                                ? 'RM ${service.servicePrice!.toStringAsFixed(0)} / hour'
                                : 'Price not available',
                              icon: ServiceHelper.getIconForService(
                                  service.serviceName),
                              color: ServiceHelper.getColorForService(
                                  service.serviceName),
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

class ServiceListItemCard extends StatelessWidget {
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