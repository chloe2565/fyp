import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/payment.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpAddPaymentScreen extends StatefulWidget {
  final VoidCallback onPaymentAdded;

  const EmpAddPaymentScreen({super.key, required this.onPaymentAdded});

  @override
  State<EmpAddPaymentScreen> createState() => EmpAddPaymentScreenState();
}

class EmpAddPaymentScreenState extends State<EmpAddPaymentScreen> {
  final formKey = GlobalKey<FormState>();
  late PaymentController controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = PaymentController();
    controller.initializeAddPage();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      showLoadingDialog(context, 'Submitting Payment...');

      try {
        await controller.submitNewPayment();
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        showSuccessDialog(
          context,
          title: 'Success',
          message: 'New payment record has been added.',
          primaryButtonText: 'OK',
          onPrimary: () {
            widget.onPaymentAdded();
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
          message: 'Failed to add payment: $e',
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
            'Add Payment Record',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Consumer<PaymentController>(
          builder: (context, controller, child) {
            if (controller.isLoadingAddData) {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment ID
                    buildTextFormField(
                      label: 'Payment ID',
                      controller: controller.paymentIDController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Billing ID
                    buildLabel('Billing ID'),
                    CustomDropdownSingle(
                      value: controller.selectedBillingID,
                      items: controller.pendingBillsDropdown.keys.toList(),
                      hint: 'Select a pending bill',
                      onChanged: (value) {
                        controller.onBillingIDSelected(value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a bill' : null,
                    ),
                    const SizedBox(height: 16),

                    // Payment Method
                    buildLabel('Payment Method'),
                    CustomDropdownSingle(
                      value: controller.selectedPaymentMethod,
                      items: const ['Bank Transfer', 'Credit Card'],
                      hint: 'Select payment method',
                      onChanged: (value) {
                        controller.onPaymentMethodSelected(value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a method' : null,
                    ),
                    const SizedBox(height: 16),

                    // Media Proof
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Media Proof',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(width: 50),
                        Expanded(child: buildMediaProofUploader(controller)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (controller.selectedMediaProof == null)
                      const Text(
                        'Please upload a media proof',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(controller.selectedMediaProof!.path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => controller.removeMediaProof(),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Total Price
                    buildTextFormField(
                      label: 'Total Price (RM)',
                      controller: controller.totalPriceController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Payment Created At
                    buildTextFormField(
                      label: 'Payment Created At',
                      controller: controller.createdAtController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Payment Status
                    buildTextFormField(
                      label: 'Payment Status',
                      controller: controller.paymentStatusController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Admin Remark
                    buildTextFormField(
                      label: 'Admin Remark',
                      controller: controller.adminRemarkController,
                      maxLines: 3,
                      validator: (value) =>
                          Validator.validateNotEmpty(value, 'Admin Remark'),
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

  Widget buildMediaProofUploader(PaymentController controller) {
    return OutlinedButton.icon(
      onPressed: () => controller.pickMediaProof(),
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Upload photo'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    String? hint,
    int maxLines = 1,
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
          maxLines: maxLines,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
