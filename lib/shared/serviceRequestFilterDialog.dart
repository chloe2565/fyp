import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/serviceRequest.dart';
import 'helper.dart';
import 'dropdownMultiOption.dart';

class ServiceRequestFilterDialog extends StatefulWidget {
  final ServiceRequestController controller;
  final Function(Map<String, String>, Map<String, String>, DateTime?, DateTime?)
  onApply;
  final VoidCallback onReset;

  const ServiceRequestFilterDialog({
    Key? key,
    required this.controller,
    required this.onApply,
    required this.onReset,
  }) : super(key: key);

  @override
  State<ServiceRequestFilterDialog> createState() =>
      ServiceRequestFilterDialogState();
}

class ServiceRequestFilterDialogState
    extends State<ServiceRequestFilterDialog> {
  late Map<String, String> selectedServices;
  late Map<String, String> selectedStatuses;
  DateTime? startDate;
  DateTime? endDate;
  String? startDateError;
  String? endDateError;

  final Map<String, String> allStatuses = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'departed': 'Departed',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    selectedServices = Map.from(widget.controller.selectedServices);
    selectedStatuses = Map.from(widget.controller.selectedStatuses);
    startDate = widget.controller.startDate;
    endDate = widget.controller.endDate;
    validateDateRange();
  }

  Map<String, String> get allServicesMap {
    return {
      for (var service in widget.controller.allServiceNames) service: service,
    };
  }

  void validateDateRange() {
    final validation = Validator.validateDateRange(
      startDate: startDate,
      endDate: endDate,
      allowFutureDates: false,
    );

    setState(() {
      startDateError = validation.startDateError;
      endDateError = validation.endDateError;
    });
  }

  bool get isFormValid {
    return Validator.isValidDateRange(
      startDate: startDate,
      endDate: endDate,
      allowFutureDates: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Stack(
                children: [
                  const Center(
                    child: Text(
                      'Filter Requests',
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

              // Service Name Filter (Multi-select)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Service Names',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomDropdownMulti(
                    allItems: allServicesMap,
                    selectedItems: selectedServices,
                    hint: 'Select services',
                    showSubtitle: false,
                    onChanged: (selected) {
                      setState(() {
                        selectedServices = selected;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Filter (Multi-select)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Statuses',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomDropdownMulti(
                    allItems: allStatuses,
                    selectedItems: selectedStatuses,
                    hint: 'Select statuses',
                    showSubtitle: false,
                    onChanged: (selected) {
                      setState(() {
                        selectedStatuses = selected;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Range Filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Date Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Start Date
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: startDate == null
                          ? ''
                          : DateFormat('dd MMM yyyy').format(startDate!),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      hintText: 'Select start date',
                      suffixIcon: startDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  startDate = null;
                                });
                                validateDateRange();
                              },
                            )
                          : const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      errorText: startDateError,
                      errorMaxLines: 2,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.orange,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          startDate = pickedDate;
                        });
                        validateDateRange();
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // End Date
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: endDate == null
                          ? ''
                          : DateFormat('dd MMM yyyy').format(endDate!),
                    ),
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      hintText: 'Select end date',
                      suffixIcon: endDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  endDate = null;
                                });
                                validateDateRange();
                              },
                            )
                          : const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      errorText: endDateError,
                      errorMaxLines: 2,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? (startDate ?? DateTime.now()),
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: DateTime.now(), // Cannot select future dates
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.orange,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          endDate = pickedDate;
                        });
                        validateDateRange();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a date range to filter requests',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isFormValid
                          ? () {
                              widget.onApply(
                                selectedServices,
                                selectedStatuses,
                                startDate,
                                endDate,
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
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

Future<void> showServiceRequestFilterDialog({
  required BuildContext context,
  required ServiceRequestController controller,
  required Function(
    Map<String, String>,
    Map<String, String>,
    DateTime?,
    DateTime?,
  )
  onApply,
  required VoidCallback onReset,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ServiceRequestFilterDialog(
          controller: controller,
          onApply: onApply,
          onReset: onReset,
        ),
      );
    },
  );
}

class FilterChipsDisplay extends StatelessWidget {
  final ServiceRequestController controller;

  const FilterChipsDisplay({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        controller.selectedServices.isNotEmpty ||
        controller.selectedStatuses.isNotEmpty ||
        controller.startDate != null ||
        controller.endDate != null;

    if (!hasFilter) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...controller.selectedServices.entries.map(
            (entry) => Chip(
              label: Text(entry.value),
              backgroundColor: Colors.orange.shade100,
              deleteIconColor: Colors.orange,
              onDeleted: () async {
                final updatedServices = Map<String, String>.from(
                  controller.selectedServices,
                );
                updatedServices.remove(entry.key);
                await controller.applyMultiFilters(
                  services: updatedServices,
                  statuses: controller.selectedStatuses,
                  startDate: controller.startDate,
                  endDate: controller.endDate,
                );
              },
            ),
          ),

          ...controller.selectedStatuses.entries.map(
            (entry) => Chip(
              label: Text(capitalizeFirst(entry.value)),
              backgroundColor: Colors.blue.shade100,
              deleteIconColor: Colors.blue,
              onDeleted: () async {
                final updatedStatuses = Map<String, String>.from(
                  controller.selectedStatuses,
                );
                updatedStatuses.remove(entry.key);
                await controller.applyMultiFilters(
                  services: controller.selectedServices,
                  statuses: updatedStatuses,
                  startDate: controller.startDate,
                  endDate: controller.endDate,
                );
              },
            ),
          ),

          if (controller.startDate != null || controller.endDate != null)
            Chip(
              label: Text(
                Formatter.formatDateRange(
                  controller.startDate,
                  controller.endDate,
                ),
              ),
              backgroundColor: Colors.green.shade100,
              deleteIconColor: Colors.green,
              onDeleted: () async {
                await controller.applyMultiFilters(
                  services: controller.selectedServices,
                  statuses: controller.selectedStatuses,
                  startDate: null,
                  endDate: null,
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Reusable widget for search field with filter button
/// Shows filter badge when filters are active
class SearchFieldWithFilter extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  const SearchFieldWithFilter({
    Key? key,
    required this.searchController,
    required this.onFilterPressed,
    required this.hasActiveFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search requests...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasActiveFilters)
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
                  child: const Icon(
                    Icons.filter_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.orange),
                onPressed: onFilterPressed,
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
    );
  }
}
