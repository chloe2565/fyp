import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/employee.dart';
import '../../controller/user.dart';
import '../../model/databaseModel.dart';
import '../../service/image_service.dart';
import '../../shared/empNavigatorBase.dart';

class HandymanHomepageScreen extends StatefulWidget {
  const HandymanHomepageScreen({Key? key}) : super(key: key);

  @override
  State<HandymanHomepageScreen> createState() => HandymanHomepageScreenState();
}

class HandymanHomepageScreenState extends State<HandymanHomepageScreen> {
  late UserController userController;
  late EmployeeController employeeController;
  int currentIndex = 0;

  // Timetable properties
  DateTime selectedWeekStart = DateTime.now();
  int timetableKey = 0;
  final List<int> timeSlots = List.generate(13, (i) => 8 + i);

  String? handymanID;
  String? handymanName;
  String? userPicName;
  bool isInitializing = true;
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    userController = UserController(
      showErrorSnackBar: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    );
    employeeController = EmployeeController();
    selectedWeekStart = getWeekStart(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeHandymanData();
    });
  }

  Future<void> initializeHandymanData() async {
    setState(() => isInitializing = true);

    try {
      if (employeeController.employee == null) {
        await employeeController.loadProfile();
      }

      final employee = employeeController.employee;
      final user = employeeController.user;
      final handyman = employeeController.handyman;

      if (employee != null && handyman != null && user != null) {
        handymanID = handyman.handymanID;
        handymanName = user.userName;
        userPicName = user.userPicName;
        await employeeController.loadHandymanTimetableData(handymanID!);
      }
    } catch (e) {
      print('Error initializing handyman data: $e');
    }

    setState(() => isInitializing = false);
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

  Future<void> handleLogout() async {
    await userController.logout(context, setState);
  }

  DateTime getWeekStart(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  List<DateTime> getWeekDays() {
    return List.generate(7, (index) {
      return DateTime(
        selectedWeekStart.year,
        selectedWeekStart.month,
        selectedWeekStart.day,
      ).add(Duration(days: index));
    });
  }

  String getWeekLabel() {
    final weekEnd = selectedWeekStart.add(const Duration(days: 6));
    final startMonth = DateFormat('MMM').format(selectedWeekStart);
    final endMonth = DateFormat('MMM').format(weekEnd);
    final startDay = selectedWeekStart.day;
    final endDay = weekEnd.day;

    if (startMonth == endMonth) {
      return 'Week ${getWeekNumber(selectedWeekStart)} ($startMonth $startDay-$endDay)';
    } else {
      return 'Week ${getWeekNumber(selectedWeekStart)} ($startMonth $startDay - $endMonth $endDay)';
    }
  }

  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }

  String getDayName(int index) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }

  bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  Future<void> showWeekPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a week',
    );

    if (picked != null) {
      final newWeekStart = getWeekStart(picked);
      if (newWeekStart != selectedWeekStart) {
        setState(() {
          selectedWeekStart = newWeekStart;
          timetableKey++;
        });
      }
    }
  }

  Map<String, dynamic> getCellStatus(DateTime date, int hour) {
    final cellStart = DateTime(date.year, date.month, date.day, hour, 0);
    final cellEnd = cellStart.add(const Duration(hours: 1));

    final unavailabilities = employeeController.getUnavailabilitiesForDate(
      date,
    );
    for (var avail in unavailabilities) {
      if (avail.availabilityStartDateTime.isBefore(cellEnd) &&
          avail.availabilityEndDateTime.isAfter(cellStart)) {
        final startTime = DateFormat(
          'HH:mm',
        ).format(avail.availabilityStartDateTime);
        final endTime = DateFormat(
          'HH:mm',
        ).format(avail.availabilityEndDateTime);

        return {
          'type': 'unavailable',
          'label': 'Leave/MC',
          'timeRange': '$startTime-$endTime',
          'color': Colors.red.shade100,
          'textColor': Colors.red.shade900,
          'borderColor': Colors.red.shade300,
        };
      }
    }

    final requests = employeeController.getServiceRequestsForDate(date);
    for (var reqData in requests) {
      final request = reqData['request'] as ServiceRequestModel;
      final serviceName = reqData['serviceName'] as String;
      final serviceDuration = reqData['serviceDuration'] as String;

      final requestStart = request.scheduledDateTime;
      final durationHours = employeeController.parseServiceDuration(
        serviceDuration,
      );
      final requestEnd = requestStart.add(
        Duration(minutes: (durationHours * 60).toInt()),
      );

      if (requestStart.isBefore(cellEnd) && requestEnd.isAfter(cellStart)) {
        final startTime = DateFormat('HH:mm').format(requestStart);
        final endTime = DateFormat('HH:mm').format(requestEnd);
        Color bgColor, textColor, borderColor;
        switch (request.reqStatus.toLowerCase()) {
          case 'confirmed':
            bgColor = Colors.blue.shade100;
            textColor = Colors.blue.shade900;
            borderColor = Colors.blue.shade300;
            break;
          case 'departed':
            bgColor = Colors.orange.shade100;
            textColor = Colors.orange.shade900;
            borderColor = Colors.orange.shade300;
            break;
          case 'completed':
            bgColor = Colors.green.shade100;
            textColor = Colors.green.shade900;
            borderColor = Colors.green.shade300;
            break;
          default:
            bgColor = Colors.grey.shade100;
            textColor = Colors.grey.shade900;
            borderColor = Colors.grey.shade300;
        }
        return {
          'type': 'service',
          'label': serviceName,
          'timeRange': '$startTime-$endTime',
          'status': request.reqStatus,
          'reqID': request.reqID,
          'color': bgColor,
          'textColor': textColor,
          'borderColor': borderColor,
        };
      }
    }

    return {
      'type': 'available',
      'label': '',
      'timeRange': '',
      'color': Colors.white,
      'textColor': Colors.grey,
      'borderColor': Colors.grey.shade200,
    };
  }

  Widget buildTimetable() {
    final weekDays = getWeekDays();
    const double timeColumnWidth = 60;
    const double dayCellWidth = 100;
    const double cellHeight = 50;

    return Container(
      key: ValueKey(timetableKey),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: timeColumnWidth,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text(
                        'Time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ...weekDays.asMap().entries.map((entry) {
                      final index = entry.key;
                      final date = entry.value;
                      final isCurrentDay = isToday(date);
                      return Container(
                        width: dayCellWidth,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrentDay
                              ? const Color(0xFFFF8C42).withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              getDayName(index),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isCurrentDay
                                    ? const Color(0xFFFF8C42)
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM').format(date),
                              style: TextStyle(
                                fontSize: 11,
                                color: isCurrentDay
                                    ? const Color(0xFFFF8C42)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              ...timeSlots.map((hour) {
                return Row(
                  children: [
                    Container(
                      width: timeColumnWidth,
                      height: cellHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ...weekDays.map((date) {
                      final cellStatus = getCellStatus(date, hour);
                      return GestureDetector(
                        onTap: () {
                          if (cellStatus['type'] == 'service')
                            showServiceRequestDetails(cellStatus);
                          else if (cellStatus['type'] == 'unavailable')
                            showUnavailabilityDetails(date, hour);
                        },
                        child: Container(
                          width: dayCellWidth,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            color: cellStatus['color'],
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade300),
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: cellStatus['label'].toString().isNotEmpty
                              ? Container(
                                  margin: const EdgeInsets.all(2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: cellStatus['borderColor'],
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cellStatus['label'],
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: cellStatus['textColor'],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (cellStatus['type'] == 'service') ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          cellStatus['status'],
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: cellStatus['textColor'],
                                          ),
                                        ),
                                      ],
                                      if (cellStatus['timeRange']
                                          .toString()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          cellStatus['timeRange'],
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            color: cellStatus['textColor'],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void showServiceRequestDetails(Map<String, dynamic> cellStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${cellStatus['label']}'),
            const SizedBox(height: 8),
            Text('Status: ${cellStatus['status']}'),
            const SizedBox(height: 8),
            Text('Request ID: ${cellStatus['reqID']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void showUnavailabilityDetails(DateTime date, int hour) {
    final unavailabilities = employeeController.getUnavailabilitiesForDate(
      date,
    );
    if (unavailabilities.isEmpty) return;
    final avail = unavailabilities.first;
    final startStr = DateFormat(
      'MMM dd, yyyy HH:mm',
    ).format(avail.availabilityStartDateTime);
    final endStr = DateFormat(
      'MMM dd, yyyy HH:mm',
    ).format(avail.availabilityEndDateTime);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave/MC Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: $startStr'),
            const SizedBox(height: 8),
            Text('To: $endStr'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              buildLegendItem(Colors.red.shade100, 'Leave/MC'),
              buildLegendItem(Colors.blue.shade100, 'Confirmed'),
              buildLegendItem(Colors.orange.shade100, 'Departed'),
              buildLegendItem(Colors.green.shade100, 'Completed'),
              buildLegendItem(Colors.white, 'Available'),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget buildQuickStats() {
    final today = DateTime.now();
    final todayRequests = employeeController.getServiceRequestsForDate(today);
    final todayUnavailabilities = employeeController.getUnavailabilitiesForDate(
      today,
    );
    final confirmedCount = todayRequests
        .where(
          (r) =>
              (r['request'] as ServiceRequestModel).reqStatus.toLowerCase() ==
              'confirmed',
        )
        .length;
    final completedCount = todayRequests
        .where(
          (r) =>
              (r['request'] as ServiceRequestModel).reqStatus.toLowerCase() ==
              'completed',
        )
        .length;

    return Row(
      children: [
        // Number of service request confirmed today
        Expanded(
          child: buildStatCard(
            'Confirmed',
            confirmedCount.toString(),
            Colors.blue,
            Icons.schedule,
          ),
        ),
        const SizedBox(width: 12),

        // Number of service request completed today
        Expanded(
          child: buildStatCard(
            'Completed',
            completedCount.toString(),
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),

        // Whether handyman have unavailability schedule today
        Expanded(
          child: buildStatCard(
            'Leave/MC',
            todayUnavailabilities.isNotEmpty ? 'Yes' : 'No',
            todayUnavailabilities.isNotEmpty ? Colors.red : Colors.grey,
            Icons.event_busy,
          ),
        ),
      ],
    );
  }

  Widget buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildDashboardContent() {
    if (isInitializing) return const Center(child: CircularProgressIndicator());

    return ListenableBuilder(
      listenable: employeeController,
      builder: (context, child) {
        if (employeeController.isLoadingTimetable)
          return const Center(child: CircularProgressIndicator());
        if (handymanID == null)
          return const Center(child: Text('Unable to load handyman profile'));

        return RefreshIndicator(
          onRefresh: () async =>
              await employeeController.loadHandymanTimetableData(handymanID!),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                buildQuickStats(),
                const SizedBox(height: 24),
                buildLegend(),
                const SizedBox(height: 24),
                const Text(
                  'Weekly Schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: showWeekPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getWeekLabel(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  key: ValueKey('timetable_$timetableKey'),
                  height: 500,
                  child: buildTimetable(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: userPicName.getImageProvider(),
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                Text(
                  handymanName ?? "Guest",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') handleLogout();
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
      body: IndexedStack(
        index: currentIndex,
        children: [
          buildDashboardContent(),
          const Center(child: Text('Requests Screen')),
        ],
      ),
      bottomNavigationBar: EmpNavigationBar(
        currentIndex: currentIndex,
        onTap: onNavBarTap,
      ),
    );
  }
}
