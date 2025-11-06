import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/billDetailViewModel.dart';
import '../../model/databaseModel.dart';
import '../../service/bill.dart';
import '../../shared/helper.dart';
import 'editBill.dart';

class EmpBillDetailScreen extends StatefulWidget {
  final BillingModel bill;

  const EmpBillDetailScreen({super.key, required this.bill});

  @override
  State<EmpBillDetailScreen> createState() => EmpBillDetailScreenState();
}

class EmpBillDetailScreenState extends State<EmpBillDetailScreen> {
  static final currencyFormat = NumberFormat("#,##0.00", "en_MY");
  static final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  final BillService billService = BillService();
  bool isLoading = true;
  bool isProcessingAction = false;
  BillDetailViewModel? detailModel;
  String? detailError;

  @override
  void initState() {
    super.initState();
    loadBillDetails();
  }

  Future<void> loadBillDetails() async {
    setState(() {
      isLoading = true;
      detailError = null;
      detailModel = null;
    });

    try {
      final billDoc = await billService.db
          .collection('Billing')
          .doc(widget.bill.billingID)
          .get();
      if (!billDoc.exists) {
        throw Exception("Bill not found.");
      }
      final freshBillModel = BillingModel.fromMap(billDoc.data()!);
      final data = await billService.getBillDetails(freshBillModel);

      setState(() {
        detailModel = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        detailError = "Failed to load billing details: $e";
        isLoading = false;
      });
    }
  }

  Future<String?> showCancelDialog() async {
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  child: Form(
                    key: dialogFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Cancel Bill?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please provide a reason for cancelling this bill. This action will set the bill and payment status to "cancelled" and the amount to RM 0.00.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Reason for Cancellation',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              Validator.validateNotEmpty(value, 'Reason'),
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              if (dialogFormKey.currentState!.validate()) {
                                Navigator.of(
                                  context,
                                ).pop(reasonController.text);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> onCancelPressed() async {
    final String? reason = await showCancelDialog();

    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() => isProcessingAction = true);
    showLoadingDialog(context, 'Cancelling Bill...');

    try {
      final Map<String, dynamic> updateData = {
        'billStatus': 'cancelled',
        'billAmt': 0.00,
        'adminRemark': reason,
      };
      await billService.updateBillAndPayment(widget.bill.billingID, updateData);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      showSuccessDialog(
        context,
        title: 'Success',
        message: 'The bill and associated payment have been cancelled.',
        primaryButtonText: 'OK',
        onPrimary: () {
          Navigator.of(context).pop(); // Close success dialog
          Navigator.of(context).pop(); // Go back
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      showErrorDialog(
        context,
        title: 'Error',
        message: 'Failed to cancel bill: $e',
      );
    } finally {
      if (mounted) {
        setState(() => isProcessingAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Billing Record Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: buildBodyContent(),
    );
  }

  Widget buildBodyContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (detailError != null) {
      return Center(child: Text(detailError!));
    }

    if (detailModel == null) {
      return const Center(child: Text('No details found.'));
    }

    return buildDetailsBody(context, detailModel!);
  }

  Widget buildDetailsBody(BuildContext context, BillDetailViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDetailItem('Billing ID', widget.bill.billingID),
          buildDetailItem('Service Request ID', widget.bill.reqID),
          buildDetailItem(
            'Service Price (RM)',
            currencyFormat.format(vm.serviceBasePrice),
          ),
          buildDetailItem(
            'Outstation Fee (RM)',
            currencyFormat.format(vm.outstationFee),
          ),
          buildDetailItem(
            'Total Price (RM)',
            currencyFormat.format(vm.totalPrice),
          ),
          buildDetailItem('Billing Status', vm.billStatus),
          buildDetailItem(
            'Billing Created At',
            dateTimeFormat.format(widget.bill.billDueDate),
          ),
          buildDetailItem(
            'Admin Remark',
            (vm.adminRemark != null && vm.adminRemark!.trim().isNotEmpty)
                ? vm.adminRemark!
                : 'None',
          ),

          Padding(
            padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
            child: Row(
              children: [
                // Edit
                Expanded(
                  child: ElevatedButton.icon(
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading || isProcessingAction
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmpEditBillScreen(
                                  bill: widget.bill,
                                  onBillUpdated: loadBillDetails,
                                ),
                              ),
                            );
                          },
                  ),
                ),

                const SizedBox(width: 16),

                // Cancel = Delete
                Expanded(
                  child: ElevatedButton.icon(
                    label: const Text('Cancel Bill'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading || isProcessingAction
                        ? null
                        : onCancelPressed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailItem(String label, String value) {
    final isStatusField = label.toLowerCase().contains('status');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            isStatusField ? capitalizeFirst(value) : value,
            style: TextStyle(
              color: isStatusField ? getStatusColor(value) : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
