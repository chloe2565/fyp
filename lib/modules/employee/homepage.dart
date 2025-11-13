import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../controller/empHomepage.dart';
import '../../service/image_service.dart';
import '../../shared/empNavigatorBase.dart';
import '../../model/databaseModel.dart';

class EmpHomepage extends StatefulWidget {
  const EmpHomepage({super.key});

  @override
  State<EmpHomepage> createState() => EmpHomepageState();
}

class EmpHomepageState extends State<EmpHomepage> {
  late UserController userController;
  late DashboardController dashboardController;
  late Future<UserModel?> userFuture;

  bool isMenuOpen = false;
  int currentIndex = 0;

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
    dashboardController = DashboardController();
    userFuture = getCurrentUser();

    // Load dashboard data
    dashboardController.loadDashboardData();
  }

  void handleLogout(BuildContext context) async {
    print("Logout selected");
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await userController.logout(context, setState);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  Future<UserModel?> getCurrentUser() async {
    return await userController.getCurrentUser();
  }

  void onNavBarTap(int index) async {
    if (index == currentIndex) {
      return;
    }

    String? routeToPush;

    switch (index) {
      case 0:
        break;
      case 1:
        routeToPush = '/empRequest';
        break;
      case 2:
        // routeToPush = '/empEmployee';
        break;
    }

    if (routeToPush != null) {
      await Navigator.pushNamed(context, routeToPush);

      if (mounted) {
        setState(() {
          currentIndex = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    userController.dispose();
    dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: FutureBuilder<UserModel?>(
          future: userFuture,
          builder: (context, snapshot) {
            ImageProvider profileImage = NetworkImage(
              FirebaseImageService.placeholderUrl,
            );

            if (snapshot.hasData && snapshot.data != null) {
              final user = snapshot.data!;
              profileImage = user.userPicName.getImageProvider();
            }

            return Row(
              children: [
                CircleAvatar(radius: 26, backgroundImage: profileImage),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    FutureBuilder<UserModel?>(
                      future: userFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            snapshot.data!.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          );
                        } else {
                          return const Text(
                            "Guest",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          // Stack(
          //   alignment: Alignment.topRight,
          //   children: [
          //     const Icon(
          //       Icons.notifications_none_outlined,
          //       color: Colors.black,
          //       size: 30,
          //     ),
          //     Container(
          //       margin: const EdgeInsets.only(top: 4, right: 2),
          //       width: 15,
          //       height: 15,
          //       decoration: BoxDecoration(
          //         color: Colors.orange,
          //         shape: BoxShape.circle,
          //         border: Border.all(color: Colors.white, width: 2),
          //       ),
          //       child: const Center(
          //         child: Text(
          //           '1',
          //           style: TextStyle(
          //             fontSize: 8,
          //             color: Colors.white,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') handleLogout(context);
                setState(() => isMenuOpen = false);
              },
              onOpened: () => setState(() => isMenuOpen = true),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout Account'),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListenableBuilder(
        listenable: dashboardController,
        builder: (context, child) {
          if (dashboardController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${dashboardController.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dashboardController.loadDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await dashboardController.loadDashboardData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildServiceRequestsCard(
                    dashboardController.requestStatusCounts,
                  ),
                  const SizedBox(height: 16),
                  buildHandymanAvailabilityCard(
                    dashboardController.handymanAvailability,
                  ),
                  const SizedBox(height: 16),
                  buildTopServicesCard(dashboardController.topServices),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: EmpNavigationBar(
        currentIndex: currentIndex,
        onTap: onNavBarTap,
      ),
    );
  }

  Widget buildServiceRequestsCard(Map<String, int> statusCounts) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today Service Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  'Number',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildStatusRow(
              'Completed',
              statusCounts['completed'] ?? 0,
              Colors.green,
            ),
            buildStatusRow(
              'On Leave',
              statusCounts['on leave'] ?? 0,
              Colors.orange,
            ),
            buildStatusRow('Late', statusCounts['late'] ?? 0, Colors.pink),
            buildStatusRow('Absent', statusCounts['absent'] ?? 0, Colors.red),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/empRequest');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View service requests',
                      style: TextStyle(color: Colors.orange),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.orange, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget buildHandymanAvailabilityCard(Map<String, int> availability) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today Handymen Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  'Number',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildStatusRow(
              'Available',
              availability['available'] ?? 0,
              Colors.green,
            ),
            buildStatusRow(
              'Unavailable',
              availability['unavailable'] ?? 0,
              Colors.red,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/empEmployee');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View employees',
                      style: TextStyle(color: Colors.orange),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.orange, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopServicesCard(Map<String, int> services) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Top 3 Popular Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Services',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  'Number',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (services.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No services data available',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...services.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/empAllService');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View services',
                      style: TextStyle(color: Colors.orange),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.orange, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
