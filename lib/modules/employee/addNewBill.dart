import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/bill.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpAddBillScreen extends StatefulWidget {
  final VoidCallback onBillAdded;
  final String? serviceRequestID;

  const EmpAddBillScreen({
    super.key,
    required this.onBillAdded,
    this.serviceRequestID,
  });

  @override
  State<EmpAddBillScreen> createState() => EmpAddBillScreenState();
}

class EmpAddBillScreenState extends State<EmpAddBillScreen> {
  final formKey = GlobalKey<FormState>();
  late BillController controller;
  final TextEditingController billingStatusController = TextEditingController(
    text: 'Pending',
  );
  bool isLoading = false;
  bool pressSelect = false;

  @override
  void initState() {
    super.initState();
    controller = BillController();
    controller.initializeAddPage();
  }

  @override
  void dispose() {
    controller.dispose();
    billingStatusController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      showLoadingDialog(context, 'Submitting Bill...');

      try {
        await controller.submitNewBill();
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        showSuccessDialog(
          context,
          title: 'Success',
          message: 'New billing record has been added.',
          primaryButtonText: 'OK',
          onPrimary: () {
            widget.onBillAdded();
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
          message: 'Failed to add bill: $e',
        );
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: isLoading ? null : () => Navigator.pop(context),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text(
            'Add Billing Record',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Consumer<BillController>(
          builder: (context, controller, child) {
            if (controller.isLoadingAddData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (widget.serviceRequestID != null && !pressSelect) {
              pressSelect = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted &&
                    controller.completableServiceRequestsDropdown.containsKey(
                      widget.serviceRequestID,
                    )) {
                  controller.onServiceRequestSelected(widget.serviceRequestID);
                }
              });
            }

            return Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Billing ID
                    buildTextFormField(
                      label: 'Billing ID',
                      controller: controller.billingIDController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Service Request ID
                    buildLabel('Service Request ID'),
                    CustomDropdownSingle(
                      value: controller.selectedServiceRequestID,
                      items: controller.completableServiceRequestsDropdown.keys
                          .toList(),
                      hint: 'Select a completed request',
                      onChanged: (value) {
                        if (widget.serviceRequestID == null) {
                          controller.onServiceRequestSelected(value);
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Please select a request' : null,
                    ),
                    const SizedBox(height: 16),

                    // Service Price
                    buildTextFormField(
                      label: 'Service Price (RM)',
                      controller: controller.servicePriceController,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Service Price'),
                    ),
                    const SizedBox(height: 16),

                    // Outstation Fee
                    buildTextFormField(
                      label: 'Outstation Fee (RM)',
                      controller: controller.outstationFeeController,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Outstation Fee'),
                    ),
                    const SizedBox(height: 16),

                    // Total Price
                    buildTextFormField(
                      label: 'Total Price (RM)',
                      controller: controller.totalPriceController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Billing Status
                    buildTextFormField(
                      label: 'Billing Status',
                      controller: billingStatusController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Billing Created At
                    buildTextFormField(
                      label: 'Billing Created At',
                      controller: controller.createdAtController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
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
            );
          },
        ),
      ),
    );
  }

  // Helper Widgets (assuming these are in your helper file)
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
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
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
