import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'helper.dart';
import 'dropdownMultiOption.dart';

class BillPaymentFilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final Map<String, String> initialStatusFilter;
  final Map<String, String> initialPaymentMethodFilter;
  final Function({
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    Map<String, String>? statusFilter,
    Map<String, String>? paymentMethodFilter,
  })
  onApply;
  final VoidCallback onReset;

  const BillPaymentFilterDialog({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialMinAmount,
    this.initialMaxAmount,
    required this.initialStatusFilter,
    required this.initialPaymentMethodFilter,
    required this.onApply,
    required this.onReset,
  }) : super(key: key);

  @override
  State<BillPaymentFilterDialog> createState() =>
      BillPaymentFilterDialogState();
}

class BillPaymentFilterDialogState extends State<BillPaymentFilterDialog> {
  DateTime? startDate;
  DateTime? endDate;
  Map<String, String> statusFilter = {};
  Map<String, String> paymentMethodFilter = {};

  TextEditingController minAmountController = TextEditingController();
  TextEditingController maxAmountController = TextEditingController();

  DateRangeValidation dateValidation = DateRangeValidation();
  String? minAmountError;
  String? maxAmountError;

  final dateFormat = DateFormat('dd MMM yyyy');

  final Map<String, String> availableStatuses = {
    'pending': 'Pending',
    'paid': 'Paid',
    'cancelled': 'Cancelled',
    'failed': 'Failed',
  };

  final Map<String, String> availablePaymentMethods = {
    'Online Banking': 'Online Banking',
    'E-Wallet': 'E-Wallet',
    'Card': 'Credit Card',
  };

  @override
  void initState() {
    super.initState();
    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;
    statusFilter = Map.from(widget.initialStatusFilter);
    paymentMethodFilter = Map.from(widget.initialPaymentMethodFilter);

    if (widget.initialMinAmount != null) {
      minAmountController.text = widget.initialMinAmount!.toStringAsFixed(2);
    }
    if (widget.initialMaxAmount != null) {
      maxAmountController.text = widget.initialMaxAmount!.toStringAsFixed(2);
    }

    minAmountController.addListener(validateInputs);
    maxAmountController.addListener(validateInputs);
  }

  @override
  void dispose() {
    minAmountController.removeListener(validateInputs);
    maxAmountController.removeListener(validateInputs);
    minAmountController.dispose();
    maxAmountController.dispose();
    super.dispose();
  }

  void validateInputs() {
    setState(() {
      dateValidation = Validator.validateDateRange(
        startDate: startDate,
        endDate: endDate,
        allowFutureDates: false,
      );

      minAmountError = Validator.validatePriceRange(
        minText: minAmountController.text,
        maxText: maxAmountController.text,
        isMinField: true,
      );

      maxAmountError = Validator.validatePriceRange(
        minText: minAmountController.text,
        maxText: maxAmountController.text,
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
      minAmountError != null ||
      maxAmountError != null;

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
                              vertical: 12,
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
                              vertical: 12,
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
              const SizedBox(height: 15),

              // Amount Range Filter
              const Text(
                'Amount Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Min Amount',
                        hintText: 'e.g. 50.00',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        errorText: minAmountError,
                        errorMaxLines: 3,
                        errorStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Max Amount',
                        hintText: 'e.g. 500.00',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        errorText: maxAmountError,
                        errorMaxLines: 3,
                        errorStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Leave empty for no limit',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 15),

              // Status Filter
              const Text(
                'Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CustomDropdownMulti(
                allItems: availableStatuses,
                selectedItems: statusFilter,
                hint: 'Select Status',
                showSubtitle: false,
                onChanged: (selectedStatuses) {
                  setState(() {
                    statusFilter = selectedStatuses;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Payment Method Filter
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Applicable to payment only',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              CustomDropdownMulti(
                allItems: availablePaymentMethods,
                selectedItems: paymentMethodFilter,
                hint: 'Select Payment Method',
                showSubtitle: false,
                onChanged: (selectedMethods) {
                  setState(() {
                    paymentMethodFilter = selectedMethods;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !hasErrors
                          ? () {
                              final minAmount = minAmountController.text.isEmpty
                                  ? null
                                  : double.tryParse(minAmountController.text);
                              final maxAmount = maxAmountController.text.isEmpty
                                  ? null
                                  : double.tryParse(maxAmountController.text);

                              widget.onApply(
                                startDate: startDate,
                                endDate: endDate,
                                minAmount: minAmount,
                                maxAmount: maxAmount,
                                statusFilter: statusFilter.isEmpty
                                    ? null
                                    : statusFilter,
                                paymentMethodFilter: paymentMethodFilter.isEmpty
                                    ? null
                                    : paymentMethodFilter,
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
