import 'package:flutter/material.dart';
import 'package:fyp/service/image_service.dart';
import '../../controller/user.dart';
import '../../controller/employee.dart';
import '../../shared/helper.dart';
import '../../shared/dropdownMultiOption.dart';
import 'addNewEmployee.dart';
import 'employeeDetail.dart';

class EmpEmployeeScreen extends StatefulWidget {
  const EmpEmployeeScreen({super.key});

  @override
  State<EmpEmployeeScreen> createState() => EmpEmployeeScreenState();
}

class EmpEmployeeScreenState extends State<EmpEmployeeScreen> {
  final TextEditingController searchController = TextEditingController();
  late UserController userController;
  final EmployeeController employeeController = EmployeeController();

  Map<String, String> selectedStatuses = {};
  Map<String, String> selectedEmpTypes = {};

  final Map<String, String> availableStatuses = {
    'active': 'Active',
    'inactive': 'Inactive',
    'resigned': 'Resigned',
    'retired': 'Retired',
  };

  final Map<String, String> availableEmpTypes = {
    'admin': 'Admin',
    'handyman': 'Handyman',
  };

  @override
  void initState() {
    super.initState();
    userController = UserController(
      showErrorSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
    employeeController.addListener(onControllerUpdate);
    initializeScreenData();
    searchController.addListener(filterEmployees);
  }

  void onControllerUpdate() {
    setState(() {});
  }

  Future<void> initializeScreenData() async {
    await employeeController.loadPageData(userController);
  }

  void filterEmployees() {
    if (!mounted) return;
    final query = searchController.text.toLowerCase();

    final filtered = employeeController.allEmployeesRaw.where((employee) {
      // Search filter
      final userName = (employee['userName'] as String? ?? '').toLowerCase();
      final empID = (employee['empID'] as String? ?? '').toLowerCase();
      final matchesSearch = userName.contains(query) || empID.contains(query);

      // Employee Type filter
      final empType = (employee['empType'] as String? ?? '').toLowerCase();
      final matchesEmpType =
          selectedEmpTypes.isEmpty || selectedEmpTypes.containsKey(empType);

      // Status filter
      final empStatus = (employee['empStatus'] as String? ?? '').toLowerCase();
      final matchesStatus =
          selectedStatuses.isEmpty || selectedStatuses.containsKey(empStatus);

      return matchesSearch && matchesEmpType && matchesStatus;
    }).toList();

    employeeController.displayedEmployees = filtered;
    employeeController.notifyListeners();
  }

  void showFilterDialog() {
    showModalBottomSheet(
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
          child: FilterDialog(
            selectedStatuses: Map.from(selectedStatuses),
            selectedEmpTypes: Map.from(selectedEmpTypes),
            availableStatuses: availableStatuses,
            availableEmpTypes: availableEmpTypes,
            onApply: (statuses, empTypes) {
              if (mounted) {
                setState(() {
                  selectedStatuses = statuses;
                  selectedEmpTypes = empTypes;
                });
                filterEmployees();
              }
            },
            onReset: () {
              if (mounted) {
                setState(() {
                  selectedStatuses.clear();
                  selectedEmpTypes.clear();
                });
                filterEmployees();
              }
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.removeListener(filterEmployees);
    searchController.dispose();
    userController.dispose();
    employeeController.removeListener(onControllerUpdate);
    employeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (employeeController.isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (employeeController.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int numberOfFilters = 0;
    if (selectedStatuses.isNotEmpty) {
      numberOfFilters++;
    }
    if (selectedEmpTypes.isNotEmpty) {
      numberOfFilters++;
    }
    final hasFilter = numberOfFilters > 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Employees',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                  builder: (context) => EmpAddEmployeeScreen(
                    onEmployeeAdded: () {
                      employeeController.loadEmployees();
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          buildSearchField(
            context: context,
            hintText: 'Search employees...',
            controller: searchController,
            onFilterPressed: showFilterDialog,
            hasFilter: hasFilter,
            numberOfFilters: numberOfFilters,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await employeeController.loadEmployees();
                filterEmployees();
              },
              child: employeeController.displayedEmployees.isEmpty
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
                                ? 'No employees found.'
                                : 'No employees available.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: employeeController.displayedEmployees.length,
                      itemBuilder: (context, index) {
                        final employee =
                            employeeController.displayedEmployees[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmpEmployeeDetailScreen(
                                    employee: employee,
                                    onDataChanged: () {
                                      employeeController.loadEmployees();
                                      filterEmployees();
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: EmployeeListItemCard(
                                name: employee['userName'] as String? ?? 'N/A',
                                userPicName: employee['userPicName'] as String?,
                                empType:
                                    employee['empType'] as String? ?? 'N/A',
                                empStatus:
                                    employee['empStatus'] as String? ?? 'N/A',
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
    );
  }
}

class FilterDialog extends StatefulWidget {
  final Map<String, String> selectedStatuses;
  final Map<String, String> selectedEmpTypes;
  final Map<String, String> availableStatuses;
  final Map<String, String> availableEmpTypes;
  final Function(Map<String, String>, Map<String, String>) onApply;
  final VoidCallback onReset;

  const FilterDialog({
    required this.selectedStatuses,
    required this.selectedEmpTypes,
    required this.availableStatuses,
    required this.availableEmpTypes,
    required this.onApply,
    required this.onReset,
    super.key,
  });

  @override
  State<FilterDialog> createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  late Map<String, String> tempSelectedStatuses;
  late Map<String, String> tempSelectedEmpTypes;

  @override
  void initState() {
    super.initState();
    tempSelectedStatuses = Map.from(widget.selectedStatuses);
    tempSelectedEmpTypes = Map.from(widget.selectedEmpTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20,
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

              // Employee Type Section
              Row(
                children: [
                  const Text(
                    'Employee Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (tempSelectedEmpTypes.isNotEmpty)
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
                        '${tempSelectedEmpTypes.length}',
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

              // Employee Type Dropdown
              CustomDropdownMulti(
                allItems: widget.availableEmpTypes,
                selectedItems: tempSelectedEmpTypes,
                hint: 'Select employee types',
                showSubtitle: false,
                onChanged: (selected) {
                  setState(() {
                    tempSelectedEmpTypes = selected;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Status Section
              Row(
                children: [
                  const Text(
                    'Employee Status',
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
                          tempSelectedEmpTypes,
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
                      child: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          tempSelectedStatuses.clear();
                          tempSelectedEmpTypes.clear();
                        });
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

class EmployeeListItemCard extends StatelessWidget {
  final String name;
  final String? userPicName;
  final String empType;
  final String empStatus;

  const EmployeeListItemCard({
    required this.name,
    this.userPicName,
    required this.empType,
    required this.empStatus,
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
          // Avatar
          CircleAvatar(
            radius: 27.5,
            backgroundColor: Colors.blue.shade200,
            child: ClipOval(
              child: userPicName.toNetworkImage(
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                errorWidget: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  capitalizeFirst(empType),
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
                      empStatus.toLowerCase(),
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    capitalizeFirst(empStatus),
                    style: TextStyle(
                      color: getStatusColor(empStatus.toLowerCase()),
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
