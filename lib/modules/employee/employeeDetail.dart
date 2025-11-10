import 'package:flutter/material.dart';
import '../../controller/employee.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';
import '../../service/image_service.dart';
import 'editEmployee.dart';
import 'handymanAvailability.dart';

class EmpEmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onDataChanged;

  const EmpEmployeeDetailScreen({
    required this.employee,
    required this.onDataChanged,
    super.key,
  });

  @override
  State<EmpEmployeeDetailScreen> createState() =>
      EmpEmployeeDetailScreenState();
}

class EmpEmployeeDetailScreenState extends State<EmpEmployeeDetailScreen> {
  final EmployeeController controller = EmployeeController();
  late Future<void> detailsFuture;

  @override
  void initState() {
    super.initState();
    detailsFuture = controller.loadSpecificEmployeeDetails(widget.employee);
  }

  void onMenuSelection(String value) {
    if (value == 'update_schedule') {
      final String handymanID = widget.employee['empID'] as String;
      final String handymanName = widget.employee['userName'] as String;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateHandymanAvailabilityScreen(
            handymanID: handymanID,
            handymanName: handymanName,
            userPicName: widget.employee['userPicName'],
            controller: controller,
          ),
        ),
      );
      print(
        'Navigating to UpdateHandymanAvailabilityScreen: ID=$handymanID, Name=$handymanName',
      );
    }
  }

  void promptUpdateStatus() {
    String? selectedStatus;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Employee Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select the new status for this employee:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomDropdownSingle(
                          hint: 'Select new status...',
                          value: selectedStatus,
                          items: const ['inactive', 'resigned', 'retired'],
                          onChanged: (newValue) {
                            setDialogState(() {
                              selectedStatus = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: selectedStatus == null
                                    ? () {}
                                    : () {
                                        Navigator.of(context).pop();
                                        handleStatusUpdate(selectedStatus!);
                                      },
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(), // close dialog
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> handleStatusUpdate(String newStatus) async {
    final statusText = capitalizeFirst(newStatus);
    final empID = widget.employee['empID'] as String;

    showConfirmDialog(
      context,
      title: 'Are you sure?',
      message:
          'Do you confirm to update this employee\'s status to "$statusText"?',
      affirmativeText: 'Confirm',
      negativeText: 'Cancel',
      onAffirmative: () async {
        try {
          showLoadingDialog(context, 'Updating Status...');
          await controller.updateEmployeeStatus(empID, newStatus);

          final updatedData = await controller.reloadEmployeeData(empID);
          if (updatedData != null && mounted) {
            setState(() {
              widget.employee.clear();
              widget.employee.addAll(updatedData);
            });
          }
          if (mounted) Navigator.of(context).pop(); // Close loading dialog

          widget.onDataChanged();
          if (mounted) {
            showSuccessDialog(
              context,
              title: 'Successful',
              message: 'The employee has been set to $newStatus.',
              primaryButtonText: 'OK',
              onPrimary: () {
                Navigator.of(context).pop(); // Pop success dialog
              },
            );
          }
        } catch (e) {
          if (mounted) Navigator.of(context).pop(); // Close loading dialog
          if (mounted) {
            showErrorDialog(
              context,
              title: 'Error',
              message: 'Failed to update status: $e',
            );
          }
        }
      },
    );
  }

  void navigateToModify() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmpEditEmployeeScreen(
          employee: widget.employee,
          onEmployeeUpdated: () {
            detailsFuture = controller.loadSpecificEmployeeDetails(
              widget.employee,
            );
            setState(() {});
            widget.onDataChanged();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHandyman = widget.employee['empType'] == 'handyman';
    final GlobalKey menuKey = GlobalKey();
    final Widget menuButton = isHandyman
        ? IconButton(
            key: menuKey,
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () async {
              final RenderBox button =
                  menuKey.currentContext!.findRenderObject() as RenderBox;
              final RenderBox overlay =
                  Overlay.of(context).context.findRenderObject() as RenderBox;
              final Offset position = button.localToGlobal(
                Offset.zero,
                ancestor: overlay,
              );

              final Size buttonSize = button.size;

              final result = await showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(
                  position.dx,
                  position.dy + buttonSize.height + 5,
                  position.dx + buttonSize.width,
                  position.dy,
                ),
                items: const [
                  PopupMenuItem<String>(
                    value: 'update_schedule',
                    child: Text('Update Schedule & Availability'),
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 8,
              );

              if (result != null) {
                onMenuSelection(result);
              }
            },
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Employee Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [menuButton],
      ),
      body: FutureBuilder<void>(
        future: detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading details: ${snapshot.error}'),
            );
          }

          return ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 55,
                                backgroundImage: (widget.employee['userPicName'] as String?).getImageProvider()
                              ),
                            ),
                            const SizedBox(height: 40),

                            buildDetailItem(
                              'Employee ID',
                              widget.employee['empID'] ?? 'N/A',
                            ),
                            buildDetailItem(
                              'Employee Type',
                              capitalizeFirst(
                                widget.employee['empType'] ?? 'N/A',
                              ),
                            ),
                            buildDetailItem(
                              'Employee Name',
                              widget.employee['userName'] ?? 'N/A',
                            ),
                            buildDetailItem(
                              'Gender',
                              Formatter.formatGender(
                                widget.employee['userGender'],
                              ),
                            ),

                            buildDetailItem(
                              'Contact Number',
                              widget.employee['userContact'] ?? 'N/A',
                            ),
                            buildDetailItem(
                              'Email Address',
                              widget.employee['userEmail'] ?? 'N/A',
                            ),

                            if (widget.employee['empType'] == 'handyman' &&
                                controller.specificHandymanModel != null) ...[
                              buildDetailItem(
                                'Bio',
                                controller
                                        .specificHandymanModel!
                                        .handymanBio
                                        .isEmpty
                                    ? 'N/A'
                                    : controller
                                          .specificHandymanModel!
                                          .handymanBio,
                              ),
                              buildDetailItem(
                                'Service Assigned',
                                controller.specificHandymanServiceNames.isEmpty
                                    ? 'N/A'
                                    : controller.specificHandymanServiceNames
                                          .join(', '),
                              ),
                            ] else if (widget.employee['empType'] == 'admin' &&
                                controller.specificServiceProviderModel !=
                                    null) ...[
                              buildDetailItem(
                                'Contact Person',
                                controller
                                    .specificServiceProviderModel!
                                    .contactPersonName,
                              ),
                            ],

                            buildDetailItem(
                              'Status',
                              capitalizeFirst(
                                widget.employee['empStatus'] ?? 'N/A',
                              ),
                              valueColor: getStatusColor(
                                widget.employee['empStatus'] ?? '',
                              ),
                            ),
                            const SizedBox(height: 32),

                            buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildDetailItem(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: navigateToModify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Modify', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: promptUpdateStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
