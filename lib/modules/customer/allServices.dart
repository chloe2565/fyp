import 'package:flutter/material.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import 'serviceDetail.dart';

class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => AllServicesScreenState();
}

class AllServicesScreenState extends State<AllServicesScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  late Future<List<ServiceModel>> servicesFuture;
  List<ServiceModel> allServices = [];
  List<ServiceModel> displayedServices = [];
  bool isLoading = true;

  double minPrice = 0;
  double maxPrice = double.infinity;

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  void filterServices() {
    if (!mounted) return;
    final query = searchController.text.toLowerCase();
    final minInput = double.tryParse(minPriceController.text) ?? 0;
    final maxInput = double.tryParse(maxPriceController.text);

    setState(() {
      displayedServices = allServices.where((service) {
        final nameMatch = service.serviceName.toLowerCase().contains(query);
        final price = service.servicePrice ?? 0;
        return nameMatch &&
            price >= minInput &&
            (maxInput == null || price <= maxInput);
      }).toList();
    });
  }

  void showFilterDialog() {
    minPriceController.text = minPrice > 0 ? minPrice.toInt().toString() : '';
    maxPriceController.text = maxPrice.isFinite
        ? maxPrice.toInt().toString()
        : '';

    showDialog(
      context: context,
      builder: (context) {
        return FilterDialog(
          minPriceController: minPriceController,
          maxPriceController: maxPriceController,
          onApply: (minVal, maxVal) {
            if (mounted) {
              setState(() {
                minPrice = minVal;
                maxPrice = maxVal;
              });
              filterServices();
            }
          },
          onReset: () {
            minPriceController.clear();
            maxPriceController.clear();
            if (mounted) {
              setState(() {
                minPrice = 0;
                maxPrice = double.infinity;
              });
              filterServices();
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.removeListener(filterServices);
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = minPrice > 0 || maxPrice.isFinite;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Services',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),

            TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasFilter)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          minPrice > 0
                              ? (maxPrice.isFinite
                                    ? '${minPrice.toInt()}–${maxPrice.toInt()}'
                                    : '${minPrice.toInt()}+')
                              : '≤${maxPrice.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: Colors.orange),
                      onPressed: showFilterDialog,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),

            const SizedBox(height: 16),

            if (hasFilter)
              Wrap(
                children: [
                  Chip(
                    label: Text(
                      minPrice > 0
                          ? (maxPrice.isFinite
                                ? 'RM${minPrice.toInt()} - RM${maxPrice.toInt()}/hr'
                                : 'RM${minPrice.toInt()}+ /hr')
                          : 'Max RM${maxPrice.toInt()}/hr',
                      style: const TextStyle(fontSize: 13),
                    ),
                    backgroundColor: Colors.orange.shade100,
                    deleteIconColor: Colors.orange,
                    onDeleted: () {
                      setState(() {
                        minPrice = 0;
                        maxPrice = double.infinity;
                        minPriceController.clear();
                        maxPriceController.clear();
                      });
                      filterServices();
                    },
                  ),
                ],
              ),

            const SizedBox(height: 8),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchController.text.isNotEmpty || hasFilter
                                ? 'No services found.'
                                : 'No services available.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayedServices.length,
                      itemBuilder: (context, index) {
                        final service = displayedServices[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServiceDetailScreen(service: service),
                              ),
                            ),
                            child: ServiceListItemCard(
                              title: service.serviceName,
                              price: service.servicePrice != null
                                  ? 'RM ${service.servicePrice!.toStringAsFixed(0)} / hour'
                                  : 'Price not available',
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
          ],
        ),
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final Function(double, double) onApply;
  final VoidCallback onReset;

  const FilterDialog({
    required this.minPriceController,
    required this.maxPriceController,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterDialog> createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  String? minError;
  String? maxError;

  @override
  void initState() {
    super.initState();
    widget.minPriceController.addListener(validate);
    widget.maxPriceController.addListener(validate);
    validateInitial();
  }

  @override
  void dispose() {
    widget.minPriceController.removeListener(validate);
    widget.maxPriceController.removeListener(validate);
    super.dispose();
  }

  void validateInitial() {
    // Initial validation without setState
    minError = Validator.validatePriceRange(
      minText: widget.minPriceController.text,
      maxText: widget.maxPriceController.text,
      isMinField: true,
    );

    maxError = Validator.validatePriceRange(
      minText: widget.minPriceController.text,
      maxText: widget.maxPriceController.text,
      isMinField: false,
    );
  }

  void validate() {
    if (!mounted) return;

    final newMinError = Validator.validatePriceRange(
      minText: widget.minPriceController.text,
      maxText: widget.maxPriceController.text,
      isMinField: true,
    );

    final newMaxError = Validator.validatePriceRange(
      minText: widget.minPriceController.text,
      maxText: widget.maxPriceController.text,
      isMinField: false,
    );

    if (newMinError != minError || newMaxError != maxError) {
      setState(() {
        minError = newMinError;
        maxError = newMaxError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Stack(
                children: [
                  const Center(
                    child: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -10,
                    top: -10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Min Price
              TextField(
                controller: widget.minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum Price',
                  prefixText: 'RM ',
                  hintText: 'e.g. 30',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  errorText: minError,
                  errorStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Max Price
              TextField(
                controller: widget.maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Maximum Price (optional)',
                  prefixText: 'RM ',
                  hintText: 'e.g. 150',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  errorText: maxError,
                  errorStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Leave max empty = no upper limit',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (minError == null && maxError == null)
                          ? () {
                              final minVal =
                                  double.tryParse(
                                    widget.minPriceController.text,
                                  ) ??
                                  0;
                              final maxVal = double.tryParse(
                                widget.maxPriceController.text,
                              );
                              widget.onApply(minVal, maxVal ?? double.infinity);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.orange.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (minError == null && maxError == null)
                          ? () {
                              final minVal =
                                  double.tryParse(
                                    widget.minPriceController.text,
                                  ) ??
                                  0;
                              final maxVal = double.tryParse(
                                widget.maxPriceController.text,
                              );
                              widget.onApply(minVal, maxVal ?? double.infinity);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.orange.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
