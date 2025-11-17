import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controller/report.dart';
import '../../shared/helper.dart';

class GenerateReportPage extends StatefulWidget {
  const GenerateReportPage({Key? key}) : super(key: key);

  @override
  State<GenerateReportPage> createState() => GenerateReportPageState();
}

class GenerateReportPageState extends State<GenerateReportPage> {
  final ReportController controller = ReportController();
  final formKey = GlobalKey<FormState>();
  final TextEditingController reportNameController = TextEditingController();
  
  String? selectedReportType;
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  
  DateRangeValidation? dateValidation;
  
  String? currentProviderID;
  bool isLoadingProviderID = true;
  String? errorLoadingProviderID;

  @override
  void initState() {
    super.initState();
    selectedReportType = controller.getReportTypes()[0];
    fetchCurrentProviderID();
  }

  Future<void> fetchCurrentProviderID() async {
    try {
      setState(() {
        isLoadingProviderID = true;
        errorLoadingProviderID = null;
      });

      final providerID = await controller.fetchCurrentProviderID();

      setState(() {
        currentProviderID = providerID;
        isLoadingProviderID = false;
      });
    } catch (e) {
      setState(() {
        errorLoadingProviderID = e.toString();
        isLoadingProviderID = false;
      });
    }
  }

  void validateDates() {
    setState(() {
      dateValidation = Validator.validateDateRange(
        startDate: startDate,
        endDate: endDate,
        allowFutureDates: false,
      );
    });
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    DateTime now = DateTime.now();
    DateTime initialDate;
    if (isStartDate) {
      initialDate = startDate ?? now;
      if (initialDate.isAfter(now)) {
        initialDate = now;
      }
    } else {
      initialDate = endDate ?? now;
      if (initialDate.isAfter(now)) {
        initialDate = now;
      }
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now, 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange[400]!,
              onPrimary: Colors.white,
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
        updateReportName();
        validateDates();
      });
    }
  }

  String generateReportName(String type) {
    if (startDate == null || endDate == null) return '';
    
    final format = DateFormat('MMM yyyy');
    
    if (startDate!.year == endDate!.year && startDate!.month == endDate!.month) {
      int lastDayOfMonth = DateTime(startDate!.year, startDate!.month + 1, 0).day;
      
      if (startDate!.day == 1 && endDate!.day == lastDayOfMonth) {
        return '${format.format(startDate!)} $type Report';
      } else {
        return '${startDate!.day}-${endDate!.day} ${format.format(startDate!)} $type Report';
      }
    }
    
    int startQuarter = ((startDate!.month - 1) ~/ 3) + 1;
    int endQuarter = ((endDate!.month - 1) ~/ 3) + 1;
    
    if (startDate!.year == endDate!.year && startQuarter == endQuarter) {
      DateTime quarterStart = DateTime(startDate!.year, (startQuarter - 1) * 3 + 1, 1);
      DateTime quarterEnd = DateTime(startDate!.year, startQuarter * 3 + 1, 0);
      
      if (startDate!.day == quarterStart.day && 
          startDate!.month == quarterStart.month &&
          endDate!.day == quarterEnd.day && 
          endDate!.month == quarterEnd.month) {
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        String startMonth = monthNames[quarterStart.month - 1];
        String endMonth = monthNames[quarterEnd.month - 1];
        return 'Q$startQuarter ${startDate!.year} ($startMonth-$endMonth) $type Report';
      }
    }
    
    if (startDate!.year == endDate!.year) {
      return '${format.format(startDate!)}-${format.format(endDate!)} $type Report';
    }
    
    return '${format.format(startDate!)}-${format.format(endDate!)} $type Report';
  }

  Future<void> generateReport() async {
    validateDates();
    
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (dateValidation != null && !dateValidation!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix date validation errors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentProviderID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider ID not loaded. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool isDuplicate = await controller.checkDuplicateReport(
        reportType: selectedReportType!,
        startDate: startDate!,
        endDate: endDate!,
        providerID: currentProviderID!,
      );

      if (isDuplicate) {
        setState(() {
          isLoading = false;
        });
        
        if (!mounted) return;
        
        showErrorDialog(
          context,
          title: 'Duplicate Report',
          message: 'A report with the same type and date range already exists. Please choose different dates or report type.',
          buttonText: 'OK',
        );
        return;
      }

      await controller.generateReport(
        context: context,
        reportName: reportNameController.text.trim(),
        reportType: selectedReportType!,
        startDate: startDate!,
        endDate: endDate!,
        providerID: currentProviderID!,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      showErrorDialog(
        context,
        title: 'Error',
        message: e.toString(),
        buttonText: 'OK',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProviderID) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Generate Report',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorLoadingProviderID != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Generate Report',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorLoadingProviderID!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchCurrentProviderID,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Generate Report',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Report Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedReportType,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: controller.getReportTypes().map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(getReportIcon(type), size: 20, color: Colors.orange[400]),
                          const SizedBox(width: 12),
                          Text(type),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedReportType = value;
                      updateReportName();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Report Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reportNameController,
              decoration: InputDecoration(
                hintText: 'Enter report name',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange[400]!, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a report name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: buildDateSelector(
                    context,
                    label: 'Start Date',
                    date: startDate,
                    isStartDate: true,
                    onTap: () => selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildDateSelector(
                    context,
                    label: 'End Date',
                    date: endDate,
                    isStartDate: false,
                    onTap: () => selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Quick Selection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                buildQuickDateButton('This Month', () {
                  DateTime now = DateTime.now();
                  int lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
                  DateTime endDate = now.day == lastDayOfMonth 
                      ? now  
                      : DateTime(now.year, now.month, now.day); 
                  
                  setState(() {
                    startDate = DateTime(now.year, now.month, 1);
                    endDate = endDate;
                    updateReportName();
                    validateDates();
                  });
                }),
                buildQuickDateButton('Last Month', () {
                  DateTime now = DateTime.now();
                  int lastMonth = now.month - 1;
                  int yearOfLastMonth = lastMonth == 0 ? now.year - 1 : now.year;
                  int monthNum = lastMonth == 0 ? 12 : lastMonth;
                  int lastDayOfLastMonth = DateTime(yearOfLastMonth, monthNum + 1, 0).day;
                  
                  setState(() {
                    startDate = DateTime(yearOfLastMonth, monthNum, 1);
                    endDate = DateTime(yearOfLastMonth, monthNum, lastDayOfLastMonth);
                    updateReportName();
                    validateDates();
                  });
                }),
                buildQuickDateButton('This Quarter', () {
                  DateTime now = DateTime.now();
                  int quarter = ((now.month - 1) ~/ 3) + 1;
                  DateTime quarterStart = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
                  DateTime quarterEnd = DateTime(now.year, quarter * 3 + 1, 0);
                  
                  if (quarterEnd.isAfter(now)) {
                    quarterEnd = now;
                  }
                  
                  setState(() {
                    startDate = quarterStart;
                    endDate = quarterEnd;
                    updateReportName();
                    validateDates();
                  });
                }),
                buildQuickDateButton('This Year', () {
                  DateTime now = DateTime.now();
                  setState(() {
                    startDate = DateTime(now.year, 1, 1);
                    endDate = now; 
                    updateReportName();
                    validateDates();
                  });
                }),
              ],
            ),
            const SizedBox(height: 32),

            if (startDate != null && endDate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Report Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Period: ${controller.formatDate(startDate!)} - ${controller.formatDate(endDate!)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duration: ${endDate!.difference(startDate!).inDays + 1} days',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDateSelector(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required bool isStartDate,
    required VoidCallback onTap,
  }) {
    String? error = isStartDate 
        ? dateValidation?.startDateError 
        : dateValidation?.endDateError;
    
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? Colors.red : Colors.grey[300]!,
                width: error != null ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: error != null ? Colors.red : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today, 
                      size: 16, 
                      color: error != null ? Colors.red : Colors.orange[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date != null ? controller.formatDate(date) : 'Select date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: error != null 
                            ? Colors.red 
                            : (date != null ? Colors.black87 : Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  void updateReportName() {
    if (selectedReportType != null && startDate != null && endDate != null) {
      reportNameController.text = generateReportName(selectedReportType!);
    }
  }

  @override
  void dispose() {
    reportNameController.dispose();
    super.dispose();
  }
}