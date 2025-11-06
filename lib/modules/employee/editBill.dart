import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/databaseModel.dart';
import '../../service/bill.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpEditBillScreen extends StatefulWidget {
  final BillingModel bill;
  final VoidCallback onBillUpdated;

  const EmpEditBillScreen({
    super.key,
    required this.bill,
    required this.onBillUpdated,
  });

  @override
  State<EmpEditBillScreen> createState() => EmpEditBillScreenState();
}

class EmpEditBillScreenState extends State<EmpEditBillScreen> {
  final formKey = GlobalKey<FormState>();
  final BillService billService = BillService();
  bool isPageLoading = true;
  bool isSubmitting = false;
  final TextEditingController billingIDController = TextEditingController();
  final TextEditingController serviceRequestIDController =
      TextEditingController();
  final TextEditingController servicePriceController = TextEditingController();
  final TextEditingController outstationFeeController = TextEditingController();
  final TextEditingController totalPriceController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();

  final List<String> billStatuses = ['pending', 'paid', 'cancelled'];
  String? selectedBillStatus;

  @override
  void initState() {
    super.initState();
    initializeFields();
    servicePriceController.addListener(calculateTotalPrice);
    outstationFeeController.addListener(calculateTotalPrice);
  }

  @override
  void dispose() {
    billingIDController.dispose();
    serviceRequestIDController.dispose();
    servicePriceController.dispose();
    outstationFeeController.dispose();
    totalPriceController.dispose();
    createdAtController.dispose();
    super.dispose();
  }

  Future<void> initializeFields() async {
    setState(() => isPageLoading = true);
    try {
      final bill = widget.bill;
      billingIDController.text = bill.billingID;
      serviceRequestIDController.text = bill.reqID;
      createdAtController.text = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(bill.billCreatedAt);
      selectedBillStatus = bill.billStatus;

      final details = await billService.getBillDetails(bill);

      servicePriceController.text = details.serviceBasePrice!.toStringAsFixed(
        2,
      );
      outstationFeeController.text = (details.outstationFee ?? 0.0)
          .toStringAsFixed(2);
      totalPriceController.text = bill.billAmt.toStringAsFixed(2);
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(
        context,
        title: 'Error',
        message: 'Failed to load bill details: $e',
      );
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
    }
  }

  void calculateTotalPrice() {
    final double servicePrice =
        double.tryParse(servicePriceController.text) ?? 0.0;
    final double outstationFee =
        double.tryParse(outstationFeeController.text) ?? 0.0;
    final double total = servicePrice + outstationFee;
    totalPriceController.text = total.toStringAsFixed(2);
  }

  Future<void> submitForm() async {
    if (formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);
      showLoadingDialog(context, 'Updating Bill...');

      try {
        final total = double.tryParse(totalPriceController.text) ?? 0.0;
        final Map<String, dynamic> updateData = {
          'billStatus': selectedBillStatus!,
          'billAmt': total,
        };
        await billService.updateBillAndPayment(
          widget.bill.billingID,
          updateData,
        );

        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        showSuccessDialog(
          context,
          title: 'Success',
          message: 'Billing record has been updated.',
          primaryButtonText: 'OK',
          onPrimary: () {
            widget.onBillUpdated();
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
          message: 'Failed to update bill: $e',
        );
      } finally {
        if (mounted) {
          setState(() => isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Billing Record',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Billing ID
                    buildTextFormField(
                      label: 'Billing ID',
                      controller: billingIDController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Service Request ID
                    buildTextFormField(
                      label: 'Service Request ID',
                      controller: serviceRequestIDController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Service Price
                    buildTextFormField(
                      label: 'Service Price (RM)',
                      controller: servicePriceController,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Service Price'),
                    ),
                    const SizedBox(height: 16),

                    // Outstation Fee
                    buildTextFormField(
                      label: 'Outstation Fee (RM)',
                      controller: outstationFeeController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Total Price
                    buildTextFormField(
                      label: 'Total Price (RM)',
                      controller: totalPriceController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Billing Status
                    buildLabel('Billing Status'),
                    CustomDropdownSingle(
                      value: selectedBillStatus?.capitalize(),
                      items: billStatuses.map((s) => s.capitalize()).toList(),
                      hint: 'Select a status',
                      onChanged: (value) {
                        setState(() {
                          selectedBillStatus = value?.toLowerCase();
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a status' : null,
                    ),
                    const SizedBox(height: 16),

                    // Billing Created At
                    buildTextFormField(
                      label: 'Billing Created At',
                      controller: createdAtController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
            ),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget buildTextFormField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
