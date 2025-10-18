import 'package:flutter/material.dart';
import '../../controller/service.dart';
import '../../model/service.dart';
import 'service_detail.dart';
import '../../helper.dart';

class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  late Future<List<ServiceModel>> _servicesFuture;
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _displayedServices = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // For filter (example: price range)
  double _minPrice = 0;
  double _maxPrice = 100; // Assume max price for filter

  @override
  void initState() {
    super.initState();
    _servicesFuture = ServiceController().getAllServices();
    _loadServices();
    _searchController.addListener(_filterServices);
  }

  Future<void> _loadServices() async {
    try {
      _allServices = await _servicesFuture;
      _displayedServices = _allServices;
    } catch (e) {
      // Handle error (e.g., show snackbar)
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _displayedServices = _allServices.where((service) {
        final matchesName = service.serviceName.toLowerCase().contains(query);
        final matchesPrice = service.servicePrice >= _minPrice &&
            service.servicePrice <= _maxPrice;
        return matchesName && matchesPrice;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _minPrice,
                min: 0,
                max: 100,
                label: 'Min: $_minPrice',
                onChanged: (value) {
                  setState(() {
                    _minPrice = value;
                  });
                },
              ),
              Slider(
                value: _maxPrice,
                min: 0,
                max: 100,
                label: 'Max: $_maxPrice',
                onChanged: (value) {
                  setState(() {
                    _maxPrice = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _filterServices();
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
    _searchController.dispose();
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
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search bar with filter
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search here..',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.orange),
                  onPressed: _showFilterDialog,
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _displayedServices.length,
                      itemBuilder: (context, index) {
                        final service = _displayedServices[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ServiceDetailPage(service: service),
                                ),
                              );
                            },
                            child: ServiceListItemCard(
                              title: service.serviceName,
                              price: 'RM ${service.servicePrice.toStringAsFixed(0)} / hour',
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

// The ServiceListItemCard widget remains exactly the same.
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