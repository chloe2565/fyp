import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controller/user.dart';
import '../../controller/empHomepage.dart';
import '../../service/image_service.dart';
import '../../shared/empNavigatorBase.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';

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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.waving_hand, size: 28, color: Colors.black),
                ),
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
    final total = statusCounts.values.fold(0, (sum, count) => sum + count);
    final hasData = total > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week Service Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!hasData)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No service requests this week',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: statusCounts.entries
                              .where((entry) => entry.value > 0)
                              .map((entry) {
                                final percentage = (entry.value / total) * 100;
                                return PieChartSectionData(
                                  color: getStatusColor(entry.key),
                                  value: entry.value.toDouble(),
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: statusCounts.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: getStatusColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    getStatusLabel(entry.key),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            // const SizedBox(height: 12),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: () {
            //       Navigator.pushNamed(context, '/empRequest');
            //     },
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: const [
            //         Text(
            //           'View service requests',
            //           style: TextStyle(color: Colors.orange),
            //         ),
            //         SizedBox(width: 4),
            //         Icon(Icons.arrow_forward, color: Colors.orange, size: 18),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget buildHandymanAvailabilityCard(Map<String, int> availability) {
    final available = availability['available'] ?? 0;
    final unavailable = availability['unavailable'] ?? 0;
    final total = available + unavailable;
    final hasData = total > 0;

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
            const SizedBox(height: 20),
            if (!hasData)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No handyman data available',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            if (available > 0)
                              PieChartSectionData(
                                color: Colors.green,
                                value: available.toDouble(),
                                title:
                                    '${((available / total) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            if (unavailable > 0)
                              PieChartSectionData(
                                color: Colors.red,
                                value: unavailable.toDouble(),
                                title:
                                    '${((unavailable / total) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '$available',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '$unavailable',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // const SizedBox(height: 12),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: () {
            //       Navigator.pushNamed(context, '/empEmployee');
            //     },
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: const [
            //         Text(
            //           'View employees',
            //           style: TextStyle(color: Colors.orange),
            //         ),
            //         SizedBox(width: 4),
            //         Icon(Icons.arrow_forward, color: Colors.orange, size: 18),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget buildTopServicesCard(Map<String, int> services) {
    final hasData = services.isNotEmpty;
    final maxValue = hasData
        ? services.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 0.0;

    final barColors = [Colors.blue, Colors.purple, Colors.teal];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week Top 3 Popular Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!hasData)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No services data available',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueGrey.shade800,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final serviceName = services.keys.elementAt(
                            groupIndex,
                          );
                          return BarTooltipItem(
                            '$serviceName\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: rod.toY.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < services.length) {
                              final serviceName = services.keys.elementAt(
                                index,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  serviceName.length > 10
                                      ? '${serviceName.substring(0, 10)}...'
                                      : serviceName,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxValue / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: services.entries.toList().asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final serviceEntry = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: serviceEntry.value.toDouble(),
                            color: barColors[index % barColors.length],
                            width: 30,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            // const SizedBox(height: 12),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: () {
            //       Navigator.pushNamed(context, '/empAllService');
            //     },
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: const [
            //         Text(
            //           'View services',
            //           style: TextStyle(color: Colors.orange),
            //         ),
            //         SizedBox(width: 4),
            //         Icon(Icons.arrow_forward, color: Colors.orange, size: 18),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
