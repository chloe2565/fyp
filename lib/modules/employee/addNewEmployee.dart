import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/employee.dart';
import '../../shared/dropdownMultiOption.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpAddEmployeeScreen extends StatefulWidget {
  final VoidCallback onEmployeeAdded;

  const EmpAddEmployeeScreen({super.key, required this.onEmployeeAdded});

  @override
  State<EmpAddEmployeeScreen> createState() => EmpAddEmployeeScreenState();
}

class EmpAddEmployeeScreenState extends State<EmpAddEmployeeScreen> {
  final formKey = GlobalKey<FormState>();
  final GlobalKey<CustomDropdownMultiState> servicesDropdownKey = GlobalKey();
  final EmployeeController controller = EmployeeController();
  final ImagePicker picker = ImagePicker();

  // Text Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();

  // State variables
  String? selectedEmpType;
  String? selectedGender;
  String selectedStatus = 'active';
  File? newProfileImage;

  late Future<Map<String, String>> servicesFuture;
  Map<String, String> selectedServices = {};

  bool isLoading = false;
  bool isPageLoading = false;

  @override
  void initState() {
    super.initState();
    servicesFuture = controller.getAllServicesMap();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    salaryController.dispose();
    bioController.dispose();
    contactPersonController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        newProfileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (isLoading) return;

    setState(() => isLoading = true);
    showLoadingDialog(context, 'Adding Employee…');

    try {
      final Map<String, dynamic> newData = {
        'userName': nameController.text.trim(),
        'userEmail': emailController.text.trim().toLowerCase(),
        'userContact': contactController.text.trim(),
        'userGender': selectedGender,
        'empType': selectedEmpType,
        'empStatus': selectedStatus,
        'empSalary': double.tryParse(salaryController.text.trim()) ?? 0.0,
        'handymanBio': bioController.text.trim(),
        'contactPersonName': contactPersonController.text.trim(),
        'assignedServiceIDs': selectedEmpType == 'handyman'
            ? selectedServices.keys.toList()
            : [],
      };

      await controller.addNewEmployee(
        newData,
        newProfileImage,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      showSuccessDialog(
        context,
        title: 'Employee Added',
        message:
            'The new employee has been created successfully.\n\nA temporary password has been sent to ${emailController.text}.',
        primaryButtonText: 'OK',
        onPrimary: () {
          widget.onEmployeeAdded();
          Navigator.of(context)
            ..pop() // close success
            ..pop(); // close add screen
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      showErrorDialog(context, title: 'Add Failed', message: e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Add Employee',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Profile Picture ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage:
                                (newProfileImage != null
                                        ? FileImage(newProfileImage!)
                                        : const AssetImage(
                                            'assets/images/profile.jpg',
                                          ))
                                    as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade700,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Employee Type ---
                    buildLabel('Employee Type', isRequired: true),
                    CustomDropdownSingle(
                      value: selectedEmpType,
                      items: const ['admin', 'handyman'],
                      hint: 'Select type',
                      onChanged: (value) {
                        setState(() => selectedEmpType = value!);
                      },
                      validator: (v) => v == null || v.isEmpty
                          ? 'Employee type is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Employee Name ---
                    buildLabel('Employee Name', isRequired: true),
                    buildTextFormField(
                      controller: nameController,
                      hint: 'Enter full name',
                      validator: Validator.validateName,
                    ),
                    const SizedBox(height: 16),

                    // --- Email Address ---
                    buildLabel('Email Address', isRequired: true),
                    buildTextFormField(
                      controller: emailController,
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validator.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Info text about password
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A temporary password will be generated and sent to the employee\'s email address.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Gender ---
                    buildLabel('Gender', isRequired: true),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Male'),
                            value: 'M',
                            groupValue: selectedGender,
                            onChanged: (value) {
                              setState(() => selectedGender = value);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Female'),
                            value: 'F',
                            groupValue: selectedGender,
                            onChanged: (value) {
                              setState(() => selectedGender = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedGender == null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          'Please select a gender',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // --- Contact Number ---
                    buildLabel('Contact Number', isRequired: true),
                    buildTextFormField(
                      controller: contactController,
                      hint: 'Enter phone number (10-15 digits)',
                      keyboardType: TextInputType.phone,
                      validator: Validator.validateContact,
                    ),
                    const SizedBox(height: 16),

                    // --- Employee Salary ---
                    buildLabel('Salary (MYR)', isRequired: true),
                    buildTextFormField(
                      controller: salaryController,
                      hint: 'e.g., 3500.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validator.validateSalary,
                    ),
                    const SizedBox(height: 16),

                    if (selectedEmpType == 'handyman') ...[
                      // --- Handyman Bio ---
                      buildLabel('Handyman Bio', isRequired: true),
                      buildTextFormField(
                        controller: bioController,
                        maxLines: 4,
                        hint:
                            'e.g., Detailing, Reliable, 5+ years experience...',
                        validator: (value) =>
                            Validator.validateNotEmpty(value, 'Handyman bio'),
                      ),
                      const SizedBox(height: 16),
                      // --- Service Assigned ---
                      buildLabel('Service Assigned', isRequired: true),
                      FutureBuilder<Map<String, String>>(
                        future: servicesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Text('Failed to load services');
                          }
                          return CustomDropdownMulti(
                            key: servicesDropdownKey,
                            allItems: snapshot.data!,
                            selectedItems: selectedServices,
                            hint: 'Select services (multiple)',
                            onChanged: (selected) {
                              setState(() => selectedServices = selected);
                            },
                            validator: (map) => map!.isEmpty
                                ? 'Select at least one service'
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (selectedEmpType == 'admin') ...[
                      // --- Contact Person Name ---
                      buildLabel('Contact Person Name', isRequired: true),
                      buildTextFormField(
                        controller: contactPersonController,
                        hint: 'Enter contact person\'s name',
                        validator: Validator.validateName,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Employee Status ---
                    buildLabel('Employee Status'),
                    CustomDropdownSingle(
                      value: selectedStatus,
                      items: const [
                        'active',
                        'inactive',
                        'resigned',
                        'retired',
                      ],
                      enabled: false,
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 32),

                    // --- Submit / Cancel ---
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16),
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

  Widget buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          children: [
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTextFormField({
    required TextEditingController controller,
    String? hint,
    bool readOnly = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: isPassword,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.orange.shade700),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }
}
