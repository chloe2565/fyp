import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../controller/employee.dart';
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
    searchController.addListener(() {
      employeeController.searchEmployees(searchController.text);
    });
  }

  void onControllerUpdate() {
    setState(() {});
  }

  Future<void> initializeScreenData() async {
    await employeeController.loadPageData(userController);
  }

  @override
  void dispose() {
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
              child: RefreshIndicator(
                onRefresh: employeeController.loadEmployees,
                child: employeeController.displayedEmployees.isEmpty
                    ? Center(
                        child: Text(
                          searchController.text.isEmpty
                              ? 'No employees available.'
                              : 'No employees found.',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
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
                                    builder: (context) =>
                                        EmpEmployeeDetailScreen(
                                          employee: employee,
                                          onDataChanged: () {
                                            employeeController.loadEmployees();
                                          },
                                        ),
                                  ),
                                );
                              },
                              child: EmployeeListItemCard(
                                name: employee['userName'] as String? ?? 'N/A',
                                userPicName: employee['userPicName'] as String?,
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

class EmployeeListItemCard extends StatelessWidget {
  final String name;
  final String? userPicName;

  const EmployeeListItemCard({required this.name, this.userPicName, super.key});

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (userPicName != null && userPicName!.isNotEmpty) {
      imageProvider = AssetImage('assets/images/${userPicName!}');
    }

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
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
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
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
