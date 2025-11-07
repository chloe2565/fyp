import 'package:flutter/material.dart';
import '../../controller/service.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import '../../shared/dropdownMultiOption.dart';
import '../../service/user.dart';
import 'addNewService.dart';
import 'serviceDetail.dart';

class EmpAllServicesScreen extends StatefulWidget {
  const EmpAllServicesScreen({super.key});

  @override
  State<EmpAllServicesScreen> createState() => EmpAllServicesScreenState();
}

class EmpAllServicesScreenState extends State<EmpAllServicesScreen> {
  final TextEditingController searchController = TextEditingController();
  final UserService userService = UserService();
  final ServiceController serviceController = ServiceController();

  List<ServiceModel> allServices = [];
  List<ServiceModel> displayedServices = [];
  bool isLoading = true;
  bool isAdmin = false;
  bool isLoadingRole = true;
  Map<String, String> selectedStatuses = {};
  Map<String, String> selectedServiceNames = {};

  final Map<String, String> availableStatuses = {
    'active': 'Active',
    'inactive': 'Inactive',
  };
  Map<String, String> availableServiceNames = {};

  @override
  void initState() {
    super.initState();
    initializeScreenData();
    searchController.addListener(filterServices);
  }

  Future<void> initializeScreenData() async {
    await loadEmployeeRole();
    await loadServices();
  }

  Future<void> loadEmployeeRole() async {
    final empInfo = await userService.getCurrentEmployeeInfo();
    setState(() {
      if (empInfo != null && empInfo['empType'] == 'admin') {
        isAdmin = true;
      }
      isLoadingRole = false;
    });
  }

  Future<void> loadServices() async {
    setState(() {
      isLoading = true;
    });

    try {
      allServices = await serviceController.empGetAllServices();
      final uniqueNames = <String, String>{};
      for (var service in allServices) {
        uniqueNames[service.serviceName] = service.serviceName;
      }

      // Sort by name
      final sortedEntries = uniqueNames.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      availableServiceNames = Map.fromEntries(sortedEntries);

      filterServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterServices() {
    if (!mounted) return;
    final query = searchController.text.toLowerCase();

    setState(() {
      displayedServices = allServices.where((service) {
        // Search filter
        final matchesName = service.serviceName.toLowerCase().contains(query);
        final matchesID = service.serviceID.toLowerCase().contains(query);
        final matchesSearch = matchesName || matchesID;

        // Service Name filter
        final matchesServiceName =
            selectedServiceNames.isEmpty ||
            selectedServiceNames.containsKey(service.serviceName);

        // Status filter
        final serviceStatus = (service.serviceStatus).toLowerCase();
        final matchesStatus =
            selectedStatuses.isEmpty ||
            selectedStatuses.containsKey(serviceStatus);

        return matchesSearch && matchesServiceName && matchesStatus;
      }).toList();
    });
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FilterDialog(
          selectedStatuses: Map.from(selectedStatuses),
          selectedServiceNames: Map.from(selectedServiceNames),
          availableStatuses: availableStatuses,
          availableServiceNames: availableServiceNames,
          onApply: (statuses, serviceNames) {
            if (mounted) {
              setState(() {
                selectedStatuses = statuses;
                selectedServiceNames = serviceNames;
              });
              filterServices();
            }
          },
          onReset: () {
            if (mounted) {
              setState(() {
                selectedStatuses.clear();
                selectedServiceNames.clear();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingRole || isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasFilter =
        selectedStatuses.isNotEmpty || selectedServiceNames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (isAdmin)
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

            // Search bar with filter icon
            TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: const TextStyle(color: Colors.grey),
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
                      ),
                    IconButton(
                      icon: Icon(Icons.tune, color: Colors.orange),
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

            // Active filters chips
            if (hasFilter)
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Service Name chips
                    ...selectedServiceNames.values.map((serviceName) {
                      return Chip(
                        avatar: const Icon(
                          Icons.build,
                          size: 16,
                          color: Colors.orange,
                        ),
                        label: Text(
                          serviceName,
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: Colors.orange.shade100,
                        deleteIconColor: Colors.orange,
                        onDeleted: () {
                          setState(() {
                            selectedServiceNames.removeWhere(
                              (key, value) => value == serviceName,
                            );
                          });
                          filterServices();
                        },
                      );
                    }).toList(),
                    // Status chips
                    ...selectedStatuses.values.map((status) {
                      return Chip(
                        avatar: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        label: Text(
                          status,
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: Colors.blue.shade100,
                        deleteIconColor: Colors.blue,
                        onDeleted: () {
                          setState(() {
                            selectedStatuses.removeWhere(
                              (key, value) => value == status,
                            );
                          });
                          filterServices();
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),

            SizedBox(height: hasFilter ? 8 : 0),

            Expanded(
              child: RefreshIndicator(
                onRefresh: loadServices,
                child: displayedServices.isEmpty
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
                            if (hasFilter) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    selectedStatuses.clear();
                                    selectedServiceNames.clear();
                                  });
                                  filterServices();
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear all filters'),
                              ),
                            ],
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
                                          isAdmin: isAdmin,
                                        ),
                                  ),
                                );
                              },
                              child: ServiceListItemCard(
                                title: service.serviceName,
                                subtitle: service.serviceID,
                                status: service.serviceStatus,
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

class FilterDialog extends StatefulWidget {
  final Map<String, String> selectedStatuses;
  final Map<String, String> selectedServiceNames;
  final Map<String, String> availableStatuses;
  final Map<String, String> availableServiceNames;
  final Function(Map<String, String>, Map<String, String>) onApply;
  final VoidCallback onReset;

  const FilterDialog({
    required this.selectedStatuses,
    required this.selectedServiceNames,
    required this.availableStatuses,
    required this.availableServiceNames,
    required this.onApply,
    required this.onReset,
    super.key,
  });

  @override
  State<FilterDialog> createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  late Map<String, String> tempSelectedStatuses;
  late Map<String, String> tempSelectedServiceNames;

  @override
  void initState() {
    super.initState();
    tempSelectedStatuses = Map.from(widget.selectedStatuses);
    tempSelectedServiceNames = Map.from(widget.selectedServiceNames);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // Service Name Section
              Row(
                children: [
                  const Text(
                    'Service Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (tempSelectedServiceNames.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tempSelectedServiceNames.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Service Name Dropdown
              CustomDropdownMulti(
                allItems: widget.availableServiceNames,
                selectedItems: tempSelectedServiceNames,
                hint: 'Select service names',
                showSubtitle: false,
                onChanged: (selected) {
                  setState(() {
                    tempSelectedServiceNames = selected;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Status Section
              Row(
                children: [
                  const Text(
                    'Service Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (tempSelectedStatuses.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tempSelectedStatuses.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Dropdown
              CustomDropdownMulti(
                allItems: widget.availableStatuses,
                selectedItems: tempSelectedStatuses,
                hint: 'Select status',
                showSubtitle: false,
                onChanged: (selected) {
                  setState(() {
                    tempSelectedStatuses = selected;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          tempSelectedStatuses,
                          tempSelectedServiceNames,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onReset();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Reset'),
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
  final String subtitle;
  final String status;
  final IconData icon;
  final Color color;

  const ServiceListItemCard({
    required this.title,
    required this.subtitle,
    required this.status,
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(
                      status.toLowerCase(),
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    capitalizeFirst(status),
                    style: TextStyle(
                      color: getStatusColor(status.toLowerCase()),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
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
