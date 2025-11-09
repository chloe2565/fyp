import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/employee.dart';
import '../../shared/helper.dart';

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
  bool isExpanded = false;

  String? fromDateError;
  String? toDateError;
  String? fromTimeError;
  String? toTimeError;

  @override
  void initState() {
    super.initState();
    selectedWeekStart = getWeekStart(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAvailability();
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
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void loadAvailability() {
    widget.controller.loadHandymanAvailability(
      widget.handymanID,
      selectedWeekStart,
    );
  }

  List<DateTime> getWeekDays() {
    return List.generate(7, (index) {
      return selectedWeekStart.add(Duration(days: index));
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

  int? getTodayIndex() {
    final weekDays = getWeekDays();
    for (int i = 0; i < weekDays.length; i++) {
      if (isToday(weekDays[i])) {
        return i;
      }
    }
    return null;
  }

  Future<void> showWeekPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedWeekStart,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a week',
    );

    if (picked != null) {
      setState(() {
        selectedWeekStart = getWeekStart(picked);
        isExpanded = false;
      });
      loadAvailability();
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
            loadAvailability();
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

  ImageProvider getAvatarImage() {
    if (widget.userPicName != null && widget.userPicName!.isNotEmpty) {
      return AssetImage('assets/images/${widget.userPicName!}');
    }
    return const AssetImage('assets/images/profile.jpg');
  }

  Widget buildDayRow(int index, DateTime date) {
    final unavailabilities = widget.controller.getUnavailabilitiesForDate(date);
    final dayName = getDayName(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(date),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Availability status
          Expanded(
            child: Column(
              children: unavailabilities.isEmpty
                  ? [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF8C42),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : unavailabilities.map((avail) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF8C42),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Unavailable',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = getTodayIndex();

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
          'Update Schedule & Availability',
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
          if (widget.controller.isLoadingAvailability) {
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
                      backgroundImage: getAvatarImage(),
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
                const SizedBox(height: 28),

                // Week Label
                const Text(
                  'Week',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Week Selector
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

                // Day Headers
                LayoutBuilder(
                  builder: (context, constraints) {
                    const dayItemWidth = 42.0;
                    final availableWidth = constraints.maxWidth;

                    double calculateOffset(int index) {
                      if (todayIndex == null) return 0;
                      return (index * (availableWidth / 7)) +
                          (availableWidth / 14) -
                          (dayItemWidth / 2);
                    }

                    return Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(7, (index) {
                              final dayName = getDayName(index);
                              final isCurrentDay = todayIndex == index;
                              return SizedBox(
                                width: dayItemWidth,
                                child: Text(
                                  dayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isCurrentDay
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrentDay
                                        ? const Color(0xFFFF8C42)
                                        : Colors.grey[600],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        if (todayIndex != null)
                          Positioned(
                            left: calculateOffset(todayIndex),
                            bottom: 0,
                            child: Container(
                              width: dayItemWidth,
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C42),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                if (!isExpanded) ...[
                  ...getWeekDays()
                      .take(2)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) => buildDayRow(entry.key, entry.value)),
                  Center(
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          isExpanded = true;
                        });
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 28,
                      ),
                    ),
                  ),
                ] else ...[
                  ...getWeekDays().asMap().entries.map(
                    (entry) => buildDayRow(entry.key, entry.value),
                  ),
                  Center(
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          isExpanded = false;
                        });
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.grey[600],
                        size: 28,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                const Text(
                  'Add Unavailable Day',
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
