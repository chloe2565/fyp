import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../controller/payment.dart';
import '../../model/databaseModel.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpEditPaymentScreen extends StatefulWidget {
  final PaymentModel payment;
  final VoidCallback onPaymentUpdated;

  const EmpEditPaymentScreen({
    super.key,
    required this.payment,
    required this.onPaymentUpdated,
  });

  @override
  State<EmpEditPaymentScreen> createState() => EmpEditPaymentScreenState();
}

class EmpEditPaymentScreenState extends State<EmpEditPaymentScreen> {
  final formKey = GlobalKey<FormState>();
  final PaymentController controller = PaymentController();
  final ImagePicker picker = ImagePicker();
  static final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final TextEditingController paymentIDController = TextEditingController();
  final TextEditingController billingIDController = TextEditingController();
  String? selectedPaymentMethod;
  File? selectedMediaProof;
  String? existingMediaProofName;
  final TextEditingController totalPriceController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController paymentStatusController = TextEditingController();
  final TextEditingController adminRemarkController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeFields();
  }

  void initializeFields() {
    final payment = widget.payment;
    paymentIDController.text = payment.payID;
    billingIDController.text = payment.billingID;
    selectedPaymentMethod = payment.payMethod;
    existingMediaProofName = payment.payMediaProof;
    totalPriceController.text = payment.payAmt.toStringAsFixed(2);
    createdAtController.text = dateTimeFormat.format(payment.payCreatedAt);
    paymentStatusController.text = payment.payStatus;
    adminRemarkController.text = payment.adminRemark;
  }

  @override
  void dispose() {
    paymentIDController.dispose();
    billingIDController.dispose();
    totalPriceController.dispose();
    createdAtController.dispose();
    paymentStatusController.dispose();
    adminRemarkController.dispose();
    super.dispose();
  }

  Future<void> pickMediaProof() async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          selectedMediaProof = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void removeMediaProof() {
    setState(() {
      selectedMediaProof = null; // Clear new file
      existingMediaProofName = null; // Clear existing proof
    });
  }

  Future<void> submitForm() async {
    bool hasMediaProof =
        existingMediaProofName != null || selectedMediaProof != null;

    if (formKey.currentState!.validate() && hasMediaProof) {
      setState(() => isLoading = true);
      showLoadingDialog(context, 'Updating Payment...');

      try {
        String mediaProofToSubmit;
        if (selectedMediaProof != null) {
          mediaProofToSubmit = selectedMediaProof!.path.split('/').last;
        } else if (existingMediaProofName != null) {
          mediaProofToSubmit = existingMediaProofName!;
        } else {
          throw Exception('Media proof is required.');
        }

        final Map<String, dynamic> updateData = {
          'payMethod': selectedPaymentMethod!,
          'payStatus': paymentStatusController.text,
          'adminRemark': adminRemarkController.text.trim(),
          'payMediaProof': mediaProofToSubmit,
        };

        await controller.submitPaymentUpdate(
          widget.payment.payID,
          widget.payment.billingID,
          updateData,
          paymentStatusController.text,
        );

        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        showSuccessDialog(
          context,
          title: 'Success',
          message: 'Payment record has been updated.',
          primaryButtonText: 'OK',
          onPrimary: () {
            widget.onPaymentUpdated();
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
          message: 'Failed to update payment: $e',
        );
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } else if (!hasMediaProof) {
      showErrorDialog(
        context,
        title: 'Missing Proof',
        message: 'Please upload a media proof.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: isLoading ? null : () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Edit Payment Record',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment ID
              buildTextFormField(
                label: 'Payment ID',
                controller: paymentIDController,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Billing ID
              buildTextFormField(
                label: 'Billing ID',
                controller: billingIDController,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Payment Method
              buildLabel('Payment Method'),
              CustomDropdownSingle(
                value: selectedPaymentMethod,
                items: const ['Bank Transfer', 'Credit Card'],
                hint: 'Select payment method',
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a method' : null,
              ),
              const SizedBox(height: 16),

              // Media Proof
              buildMediaProofSection(),
              const SizedBox(height: 16),

              // Total Price
              buildTextFormField(
                label: 'Total Price (RM)',
                controller: totalPriceController,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Payment Created At
              buildTextFormField(
                label: 'Payment Created At',
                controller: createdAtController,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Payment Status
              buildLabel('Payment Status'),
              CustomDropdownSingle(
                value: paymentStatusController.text,
                items: const ['Paid', 'Pending', 'Failed'],
                hint: 'Select payment status',
                onChanged: (value) {
                  setState(() {
                    paymentStatusController.text = value ?? 'Pending';
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a status' : null,
              ),
              const SizedBox(height: 16),

              // Admin Remark
              buildTextFormField(
                label: 'Admin Remark',
                controller: adminRemarkController,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLoading ? 'Updating...' : 'Update',
                        style: const TextStyle(fontSize: 16),
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
                        style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget buildMediaProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildLabel('Media Proof'),
            const SizedBox(width: 50),
            Expanded(
              child: buildMediaProofUploader(
                text:
                    existingMediaProofName != null || selectedMediaProof != null
                    ? 'Change photo'
                    : 'Upload photo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (selectedMediaProof != null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      selectedMediaProof!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: buildRemoveButton(removeMediaProof),
                  ),
                ],
              ),
            ],
          )
        else if (existingMediaProofName != null &&
            existingMediaProofName!.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/payments/$existingMediaProofName',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: buildRemoveButton(removeMediaProof),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: buildRemoveButton(removeMediaProof),
                  ),
                ],
              ),
            ],
          )
        else
          const Text(
            'Please upload a media proof',
            style: TextStyle(color: Colors.red, fontSize: 13),
          ),
      ],
    );
  }

  Widget buildMediaFilePreview(File file) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: buildRemoveButton(removeMediaProof),
            ),
          ],
        ),
        const SizedBox(height: 8),
        buildMediaProofUploader(text: 'Change photo'),
      ],
    );
  }

  Widget buildMediaAssetPreview(String assetPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: buildRemoveButton(removeMediaProof),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: buildRemoveButton(removeMediaProof),
            ),
          ],
        ),
        const SizedBox(height: 8),
        buildMediaProofUploader(text: 'Change photo'),
      ],
    );
  }

  Widget buildRemoveButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(2),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }

  Widget buildMediaProofUploader({String text = 'Upload photo'}) {
    return OutlinedButton.icon(
      onPressed: pickMediaProof,
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: Text(text),
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
