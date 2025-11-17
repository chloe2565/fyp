import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/employee.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import '../../service/image_service.dart';

class UpdateHandymanAvailabilityScreen extends StatefulWidget {
  final String handymanID;
  final String handymanName;
  final String? userPicName;
  final EmployeeController controller;

  const UpdateHandymanAvailabilityScreen({
    Key? key,
    required this.handymanID,
    required this.handymanName,
    this.userPicName,
    required this.controller,
  }) : super(key: key);

  @override
  State<UpdateHandymanAvailabilityScreen> createState() =>
      UpdateHandymanAvailabilityScreenState();
}

class UpdateHandymanAvailabilityScreenState
    extends State<UpdateHandymanAvailabilityScreen> {
  DateTime selectedWeekStart = DateTime.now();
  DateTime? unavailableFromDate;
  DateTime? unavailableToDate;
  TimeOfDay unavailableFromTime = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay unavailableToTime = const TimeOfDay(hour: 19, minute: 30);

  String? fromDateError;
  String? toDateError;
  String? fromTimeError;
  String? toTimeError;

  // Key to force timetable rebuild when week changes
  int timetableKey = 0;

  // Time slots for the timetable (8 AM to 8 PM)
  final List<int> timeSlots = List.generate(
    13,
    (i) => 8 + i,
  ); // 8 to 20 (8 AM to 8 PM)

  @override
  void initState() {
    super.initState();
    selectedWeekStart = getWeekStart(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTimetableData();
    });
  }

  void resetInputFields() {
    setState(() {
      unavailableFromDate = null;
      unavailableToDate = null;
      unavailableFromTime = const TimeOfDay(hour: 9, minute: 30);
      unavailableToTime = const TimeOfDay(hour: 12, minute: 30);
      fromDateError = null;
      toDateError = null;
      fromTimeError = null;
      toTimeError = null;
    });
  }

  DateTime getWeekStart(DateTime date) {
    // Normalize to start of day first
    final normalizedDate = DateTime(date.year, date.month, date.day);
    // Get Monday of the week (weekday: 1=Monday, 7=Sunday)
    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  void loadTimetableData() {
    widget.controller.loadHandymanTimetableData(widget.handymanID).then((_) {
      // Debug: Print all loaded data
      print('=== LOADED DATA SUMMARY ===');
      print(
        'Total availability records: ${widget.controller.handymanAvailabilities.length}',
      );
      for (var avail in widget.controller.handymanAvailabilities) {
        print(
          '  Availability: ${avail.availabilityStartDateTime} to ${avail.availabilityEndDateTime}',
        );
      }
      print(
        'Total service requests: ${widget.controller.handymanServiceRequests.length}',
      );
      for (var req in widget.controller.handymanServiceRequests) {
        final request = req['request'] as ServiceRequestModel;
        print(
          '  Request ${request.reqID}: ${request.scheduledDateTime} - Status: ${request.reqStatus}',
        );
      }
      print('=== END DATA SUMMARY ===');
    });
  }

  List<DateTime> getWeekDays() {
    final days = List.generate(7, (index) {
      return DateTime(
        selectedWeekStart.year,
        selectedWeekStart.month,
        selectedWeekStart.day,
      ).add(Duration(days: index));
    });
    print(
      'Week days for selected week: ${days.map((d) => '${d.year}-${d.month}-${d.day}').join(', ')}',
    );
    return days;
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
        print('=== WEEK CHANGED ===');
        print('Old week start: $selectedWeekStart');
        print('New week start: $newWeekStart');

        setState(() {
          selectedWeekStart = newWeekStart;
          timetableKey++; // Force timetable to rebuild with new key
        });

        // Debug: Check what data matches the new week
        final weekEnd = newWeekStart.add(const Duration(days: 7));
        print('Week range: $newWeekStart to $weekEnd');

        int availCount = 0;
        int reqCount = 0;

        for (var avail in widget.controller.handymanAvailabilities) {
          if (avail.availabilityStartDateTime.isBefore(weekEnd) &&
              avail.availabilityEndDateTime.isAfter(newWeekStart)) {
            availCount++;
            print('  Match availability: ${avail.availabilityStartDateTime}');
          }
        }

        for (var reqData in widget.controller.handymanServiceRequests) {
          final request = reqData['request'] as ServiceRequestModel;
          if (request.scheduledDateTime.isAfter(
                newWeekStart.subtract(const Duration(seconds: 1)),
              ) &&
              request.scheduledDateTime.isBefore(weekEnd)) {
            reqCount++;
            print('  Match request: ${request.scheduledDateTime}');
          }
        }

        print(
          'Total matches for new week: $availCount availabilities, $reqCount requests',
        );
        print('=== END WEEK CHANGE ===');
      }
    }
  }

  Future<void> selectDate(BuildContext context, bool isFrom) async {
    final initialDate = isFrom
        ? (unavailableFromDate ?? DateTime.now())
        : (unavailableToDate ?? DateTime.now().add(const Duration(days: 1)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(DateTime.now())
          ? DateTime.now()
          : initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          unavailableFromDate = picked;
        } else {
          unavailableToDate = picked;
        }
        validateDateTimeInputs();
      });
    }
  }

  Future<void> selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? unavailableFromTime : unavailableToTime,
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          unavailableFromTime = picked;
        } else {
          unavailableToTime = picked;
        }
        validateDateTimeInputs();
      });
    }
  }

  void validateDateTimeInputs() {
    setState(() {
      fromDateError = Validator.validateSelectedDateTime(
        unavailableFromDate,
        unavailableFromTime,
        'Start Date/Time',
      );
      toDateError = Validator.validateSelectedDateTime(
        unavailableToDate,
        unavailableToTime,
        'End Date/Time',
      );
      fromTimeError = fromDateError;
      toTimeError = toDateError;

      if (fromDateError == null && toDateError == null) {
        final fromDateTime = DateTime(
          unavailableFromDate!.year,
          unavailableFromDate!.month,
          unavailableFromDate!.day,
          unavailableFromTime.hour,
          unavailableFromTime.minute,
        );
        final toDateTime = DateTime(
          unavailableToDate!.year,
          unavailableToDate!.month,
          unavailableToDate!.day,
          unavailableToTime.hour,
          unavailableToTime.minute,
        );

        final rangeError = Validator.validateDateTimeRange(
          startDateTime: fromDateTime,
          endDateTime: toDateTime,
          fieldName: 'Unavailability period',
        );

        if (rangeError != null) {
          fromDateError = rangeError;
          toDateError = rangeError;
          fromTimeError = rangeError;
          toTimeError = rangeError;
        } else {
          fromDateError = null;
          toDateError = null;
          fromTimeError = null;
          toTimeError = null;
        }
      }
    });
  }

  Future<void> submitUnavailability() async {
    validateDateTimeInputs();

    if (fromDateError != null ||
        toDateError != null ||
        fromTimeError != null ||
        toTimeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the input errors above.')),
      );
      return;
    }

    final fromDateTime = DateTime(
      unavailableFromDate!.year,
      unavailableFromDate!.month,
      unavailableFromDate!.day,
      unavailableFromTime.hour,
      unavailableFromTime.minute,
    );

    final toDateTime = DateTime(
      unavailableToDate!.year,
      unavailableToDate!.month,
      unavailableToDate!.day,
      unavailableToTime.hour,
      unavailableToTime.minute,
    );

    showLoadingDialog(context, 'Adding unavailability...');

    try {
      await widget.controller.addHandymanUnavailability(
        widget.handymanID,
        fromDateTime,
        toDateTime,
      );
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        showSuccessDialog(
          context,
          title: 'Success!',
          message: 'Handyman unavailability added successfully.',
          primaryButtonText: 'OK',
          onPrimary: () {
            Navigator.of(context).pop();
            resetInputFields();
            loadTimetableData();
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        showErrorDialog(
          context,
          title: 'Error',
          message: 'Failed to add unavailability.',
        );
      }
    }
  }

  // Get cell status for timetable
  Map<String, dynamic> getCellStatus(DateTime date, int hour) {
    final cellStart = DateTime(date.year, date.month, date.day, hour, 0);
    final cellEnd = cellStart.add(const Duration(hours: 1));

    // Check for leave/MC (unavailability)
    final unavailabilities = widget.controller.getUnavailabilitiesForDate(date);

    if (unavailabilities.isNotEmpty) {
      print(
        'Found ${unavailabilities.length} unavailabilities for date: ${date.year}-${date.month}-${date.day}',
      );
    }

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

    // Check for service requests
    final requests = widget.controller.getServiceRequestsForDate(date);

    if (requests.isNotEmpty) {
      print(
        'Found ${requests.length} service requests for date: ${date.year}-${date.month}-${date.day}',
      );
    }

    for (var reqData in requests) {
      final request = reqData['request'] as ServiceRequestModel;
      final serviceName = reqData['serviceName'] as String;
      final serviceDuration = reqData['serviceDuration'] as String;

      final requestStart = request.scheduledDateTime;
      final durationHours = widget.controller.parseServiceDuration(
        serviceDuration,
      );
      final requestEnd = requestStart.add(
        Duration(minutes: (durationHours * 60).toInt()),
      );

      if (requestStart.isBefore(cellEnd) && requestEnd.isAfter(cellStart)) {
        final startTime = DateFormat('HH:mm').format(requestStart);
        final endTime = DateFormat('HH:mm').format(requestEnd);
        Color bgColor;
        Color textColor;
        Color borderColor;

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

    // Available
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
              // Header row with day names
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    // Empty cell for time column
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
                    // Day headers
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
              // Time slots rows
              ...timeSlots.map((hour) {
                return Row(
                  children: [
                    // Time label
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
                    // Day cells
                    ...weekDays.map((date) {
                      final cellStatus = getCellStatus(date, hour);

                      return GestureDetector(
                        onTap: () {
                          if (cellStatus['type'] == 'service') {
                            showServiceRequestDetails(cellStatus);
                          } else if (cellStatus['type'] == 'unavailable') {
                            showUnavailabilityDetails(date, hour);
                          }
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
    final unavailabilities = widget.controller.getUnavailabilitiesForDate(date);
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
          const Text(
            'Legend',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Handyman Availability Timetable',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          if (widget.controller.isLoadingTimetable) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: widget.userPicName.getImageProvider(),
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.handymanName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Legend
                buildLegend(),
                const SizedBox(height: 20),

                // Week Selector
                const Text(
                  'Select Week',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
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
                const SizedBox(height: 20),

                // Timetable
                const Text(
                  'Weekly Timetable',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  key: ValueKey('timetable_$timetableKey'),
                  height: 500,
                  child: buildTimetable(),
                ),

                const SizedBox(height: 28),

                // Add Unavailable Day Section
                const Text(
                  'Add Leave/MC Period',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Date Pickers Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: fromDateError != null
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    unavailableFromDate == null
                                        ? 'Start Date'
                                        : DateFormat(
                                            'dd MMM yyyy',
                                          ).format(unavailableFromDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: unavailableFromDate == null
                                          ? Colors.grey[500]
                                          : Colors.black,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (fromDateError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                fromDateError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'To',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: toDateError != null
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    unavailableToDate == null
                                        ? 'End Date'
                                        : DateFormat(
                                            'dd MMM yyyy',
                                          ).format(unavailableToDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: unavailableToDate == null
                                          ? Colors.grey[500]
                                          : Colors.black,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (toDateError != null && fromDateError == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                toDateError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time Pickers Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => selectTime(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: fromTimeError != null
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    unavailableFromTime.format(context),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (fromTimeError != null && fromDateError == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                fromTimeError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'To',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => selectTime(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: toTimeError != null
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    unavailableToTime.format(context),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (toTimeError != null &&
                              fromDateError == null &&
                              toDateError == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                toTimeError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: submitUnavailability,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: resetInputFields,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
