import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/helper.dart';

class RatingReviewFilterDialog extends StatefulWidget {
  final String? initialReplyFilter;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final double? initialMinRating;
  final double? initialMaxRating;
  final Function({
    String? replyFilter,
    DateTime? startDate,
    DateTime? endDate,
    double? minRating,
    double? maxRating,
  })
  onApply;
  final VoidCallback onReset;

  const RatingReviewFilterDialog({
    required this.onApply,
    required this.onReset,
    this.initialReplyFilter,
    this.initialStartDate,
    this.initialEndDate,
    this.initialMinRating,
    this.initialMaxRating,
    Key? key,
  }) : super(key: key);

  @override
  State<RatingReviewFilterDialog> createState() =>
      RatingReviewFilterDialogState();
}

class RatingReviewFilterDialogState extends State<RatingReviewFilterDialog> {
  String? replyFilter;
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController minRatingController = TextEditingController();
  TextEditingController maxRatingController = TextEditingController();

  DateRangeValidation dateValidation = DateRangeValidation();
  String? minRatingError;
  String? maxRatingError;

  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    replyFilter = widget.initialReplyFilter;
    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;

    if (widget.initialMinRating != null) {
      minRatingController.text = widget.initialMinRating!.toStringAsFixed(1);
    }
    if (widget.initialMaxRating != null) {
      maxRatingController.text = widget.initialMaxRating!.toStringAsFixed(1);
    }

    minRatingController.addListener(validateInputs);
    maxRatingController.addListener(validateInputs);
  }

  @override
  void dispose() {
    minRatingController.removeListener(validateInputs);
    maxRatingController.removeListener(validateInputs);
    minRatingController.dispose();
    maxRatingController.dispose();
    super.dispose();
  }

  void validateInputs() {
    setState(() {
      dateValidation = Validator.validateDateRange(
        startDate: startDate,
        endDate: endDate,
        allowFutureDates: false,
      );

      minRatingError = Validator.validateRatingRange(
        minText: minRatingController.text,
        maxText: maxRatingController.text,
        isMinField: true,
      );

      maxRatingError = Validator.validateRatingRange(
        minText: minRatingController.text,
        maxText: maxRatingController.text,
        isMinField: false,
      );
    });
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        validateInputs();
      });
    }
  }

  bool get hasErrors =>
      !dateValidation.isValid ||
      minRatingError != null ||
      maxRatingError != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Reply Status Filter
              const Text(
                'Reply Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String?>(
                      title: const Text(
                        'All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: null,
                      groupValue: replyFilter,
                      onChanged: (value) {
                        setState(() => replyFilter = value);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    RadioListTile<String?>(
                      title: const Text(
                        'With Reply',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: 'with',
                      groupValue: replyFilter,
                      onChanged: (value) {
                        setState(() => replyFilter = value);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    RadioListTile<String?>(
                      title: const Text(
                        'Without Reply',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: 'without',
                      groupValue: replyFilter,
                      onChanged: (value) {
                        setState(() => replyFilter = value);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Date Range Filter
              const Text(
                'Date Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: dateValidation.startDateError != null
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    startDate != null
                                        ? dateFormat.format(startDate!)
                                        : 'Start Date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: startDate != null
                                          ? Colors.black
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (startDate != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        startDate = null;
                                        validateInputs();
                                      });
                                    },
                                    child: Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (dateValidation.startDateError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateValidation.startDateError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: dateValidation.endDateError != null
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    endDate != null
                                        ? dateFormat.format(endDate!)
                                        : 'End Date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: endDate != null
                                          ? Colors.black
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (endDate != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        endDate = null;
                                        validateInputs();
                                      });
                                    },
                                    child: Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (dateValidation.endDateError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateValidation.endDateError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Rating Range Filter
              const Text(
                'Rating Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minRatingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Min Rating',
                        hintText: 'e.g. 3.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        errorText: minRatingError,
                        errorMaxLines: 3,
                        errorStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxRatingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Max Rating',
                        hintText: 'e.g. 5.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        errorText: maxRatingError,
                        errorMaxLines: 3,
                        errorStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Leave empty for no limit (0.0 - 5.0)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !hasErrors
                          ? () {
                              final minRating = minRatingController.text.isEmpty
                                  ? null
                                  : double.tryParse(minRatingController.text);
                              final maxRating = maxRatingController.text.isEmpty
                                  ? null
                                  : double.tryParse(maxRatingController.text);

                              widget.onApply(
                                replyFilter: replyFilter,
                                startDate: startDate,
                                endDate: endDate,
                                minRating: minRating,
                                maxRating: maxRating,
                              );
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
