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
  static final dateTimeFormat = DateFormat('MMMM dd, yyyy hh:mm a');
  static final dateFormat = DateFormat('MMMM dd, yyyy');

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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          validator: (value) => Validator.validateNotEmpty(value, 'Reason'),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
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
                                Navigator.of(context).pop(reasonController.text);
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
          'Billing Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
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
    final icon = ServiceHelper.getIconForService(vm.serviceName);
    final bgColor = ServiceHelper.getColorForService(vm.serviceName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header Card
          buildServiceHeaderCard(context, vm, icon, bgColor),
          const SizedBox(height: 12),

          // Status Card
          buildStatusCard(context, vm),
          const SizedBox(height: 12),

          // Customer Information Card
          buildCustomerInfoCard(context, vm),
          const SizedBox(height: 12),

          // Service & Handyman Card
          buildServiceDetailsCard(context, vm),
          const SizedBox(height: 12),

          // Pricing Breakdown Card
          buildPricingCard(context, vm),
          const SizedBox(height: 12),

          // Timeline Card
          buildTimelineCard(context, vm),
          const SizedBox(height: 12),

          // Admin Remarks Card
          if (vm.adminRemark != null && vm.adminRemark!.trim().isNotEmpty)
            buildAdminRemarksCard(context, vm.adminRemark!),
          if (vm.adminRemark != null && vm.adminRemark!.trim().isNotEmpty)
            const SizedBox(height: 12),

          // Action Buttons
          buildActionButtons(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildServiceHeaderCard(
    BuildContext context,
    BillDetailViewModel vm,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bill ID: ${widget.bill.billingID}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard(BuildContext context, BillDetailViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: getStatusColor(vm.billStatus),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Billing Status: ',
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          Text(
            capitalizeFirst(vm.billStatus),
            style: TextStyle(
              color: getStatusColor(vm.billStatus),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCustomerInfoCard(BuildContext context, BillDetailViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(Icons.person, 'Name', vm.customerName),
          const SizedBox(height: 12),
          buildInfoRow(Icons.phone, 'Contact', vm.customerContact),
          const SizedBox(height: 12),
          buildInfoRow(Icons.location_on, 'Address', vm.customerAddress),
        ],
      ),
    );
  }

  Widget buildServiceDetailsCard(BuildContext context, BillDetailViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(Icons.build, 'Service', vm.serviceName),
          const SizedBox(height: 12),
          buildInfoRow(Icons.engineering, 'Handyman', vm.handymanName),
          const SizedBox(height: 12),
          buildInfoRow(Icons.receipt, 'Request ID', widget.bill.reqID),
        ],
      ),
    );
  }

  Widget buildPricingCard(BuildContext context, BillDetailViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Service Price', vm.serviceBasePrice ?? 0.0),
          const SizedBox(height: 8),
          _buildPriceRow('Outstation Fee', vm.outstationFee),
          const Divider(height: 24),
          _buildPriceRow('Total Amount', vm.totalPrice, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          'RM ${currencyFormat.format(amount)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.green[700] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget buildTimelineCard(BuildContext context, BillDetailViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildInfoRow(
            Icons.schedule,
            'Service Scheduled',
            dateTimeFormat.format(vm.bookingTimestamp),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.check_circle,
            'Service Completed',
            dateTimeFormat.format(vm.serviceCompleteTimestamp),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.receipt_long,
            'Bill Created',
            dateTimeFormat.format(widget.bill.billCreatedAt),
          ),
          const SizedBox(height: 12),
          buildInfoRow(
            Icons.event,
            'Due Date',
            dateFormat.format(widget.bill.billDueDate),
          ),
          if (vm.paymentTimestamp != null) ...[
            const SizedBox(height: 12),
            buildInfoRow(
              Icons.paid,
              'Payment Received',
              dateTimeFormat.format(vm.paymentTimestamp!),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildAdminRemarksCard(BuildContext context, String remark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Admin Remarks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            remark,
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[900],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Bill'),
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
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel Bill'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading || isProcessingAction ? null : onCancelPressed,
          ),
        ),
      ],
    );
  }
}