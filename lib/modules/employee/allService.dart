import 'package:flutter/material.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import 'addNewService.dart';
import 'serviceDetail.dart';

class EmpAllServicesScreen extends StatefulWidget {
  const EmpAllServicesScreen({super.key});

  @override
  State<EmpAllServicesScreen> createState() => EmpAllServicesScreenState();
}

class EmpAllServicesScreenState extends State<EmpAllServicesScreen> {
  final TextEditingController searchController = TextEditingController();
  late Future<List<ServiceModel>> servicesFuture;
  List<ServiceModel> allServices = [];
  List<ServiceModel> displayedServices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadServices();
    searchController.addListener(filterServices);
  }

  Future<void> loadServices() async {
    setState(() {
      isLoading = true;
      servicesFuture = ServiceController().empGetAllServices();
    });
    try {
      allServices = await servicesFuture;
      filterServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
      }
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
        final matchesID = service.serviceID.toLowerCase().contains(query);
        return matchesName || matchesID;
      }).toList();
    });
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
        title: const Text(
          'Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmpAddServiceScreen(
                    onServiceAdded: () {
                      loadServices();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
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
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.orange),
                  onPressed: () {
                    // TODO: Show filter dialog
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: loadServices,
                      child: displayedServices.isEmpty
                          ? Center(
                              child: Text(
                                searchController.text.isEmpty
                                    ? 'No services available.'
                                    : 'No services found.',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
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
                                              EmpServiceDetailScreen(
                                                service: service,
                                                onDataChanged: () {
                                                  loadServices();
                                                },
                                              ),
                                        ),
                                      );
                                    },
                                    child: ServiceListItemCard(
                                      title: service.serviceName,
                                      subtitle: service.serviceID,
                                      icon: ServiceHelper.getIconForService(
                                        service.serviceName,
                                      ),
                                      color: ServiceHelper.getColorForService(
                                        service.serviceName,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
  final String subtitle;
  final IconData icon;
  final Color color;

  const ServiceListItemCard({
    required this.title,
    required this.subtitle,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
