import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp/service/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/employee.dart';
import '../../shared/dropdownMultiOption.dart';
import '../../shared/dropdownSingleOption.dart';
import '../../shared/helper.dart';

class EmpEditEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onEmployeeUpdated;

  const EmpEditEmployeeScreen({
    super.key,
    required this.employee,
    required this.onEmployeeUpdated,
  });

  @override
  State<EmpEditEmployeeScreen> createState() => EmpEditEmployeeScreenState();
}

class EmpEditEmployeeScreenState extends State<EmpEditEmployeeScreen> {
  final formKey = GlobalKey<FormState>();
  final GlobalKey<CustomDropdownMultiState> servicesDropdownKey = GlobalKey();
  final EmployeeController controller = EmployeeController();
  final ImagePicker picker = ImagePicker();
  final TextEditingController empIDController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String? selectedEmpType;
  String? selectedGender;
  String? selectedStatus;
  File? newProfileImage;
  String? currentProfilePicName;
  double? handymanRating;

  late Future<Map<String, String>> servicesFuture;
  Map<String, String> allServicesMap = {};
  Map<String, String> selectedServices = {};

  bool isLoading = false;
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();
    servicesFuture = controller.getAllServicesMap();
    initializeFields();
  }

  Future<void> initializeFields() async {
    setState(() => isPageLoading = true);
    final emp = widget.employee;

    try {
      empIDController.text = emp['empID'] ?? '';
      nameController.text = emp['userName'] ?? '';
      contactController.text = emp['userContact'] ?? '';
      emailController.text = emp['userEmail'] ?? '';
      selectedEmpType = emp['empType'];
      selectedStatus = emp['empStatus'];
      selectedGender = emp['userGender'];
      currentProfilePicName = emp['userPicName'];

      allServicesMap = await servicesFuture;

      if (selectedEmpType == 'handyman') {
        selectedServices = await controller.getAssignedServicesMap(
          emp['empID'],
        );

        if (emp.containsKey('handymanBio')) {
          bioController.text = emp['handymanBio'] ?? '';
        } else {
          final handymanDetails = await controller.getHandymanDetails(
            emp['empID'],
          );

          if (handymanDetails != null) {
            bioController.text = handymanDetails['handymanBio'] ?? '';
            handymanRating = handymanDetails['handymanRating'] as double?;
          } else if (emp.containsKey('handymanBio')) {
            bioController.text = emp['handymanBio'] ?? '';
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isPageLoading = false);
      }
    }
  }

  @override
  void dispose() {
    empIDController.dispose();
    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    bioController.dispose();
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
    if (!formKey.currentState!.validate() || isLoading) return;

    if (selectedEmpType == 'handyman') {
      final dropdownState = servicesDropdownKey.currentState;
      if (dropdownState != null) {
        dropdownState.validate();
        if (dropdownState.errorText != null) {
          showErrorDialog(
            context,
            title: 'Services Required',
            message: dropdownState.errorText!,
          );
          return;
        }
      }
    }

    setState(() => isLoading = true);
    showLoadingDialog(context, 'Updating Employee…');

    try {
      final Map<String, dynamic> updatedData = {
        'userID': widget.employee['userID'],
        'empID': widget.employee['empID'],
        'userName': nameController.text,
        'userContact': contactController.text,
        'userEmail': emailController.text,
        'userGender': selectedGender,
        'empType': selectedEmpType,
        'empStatus': selectedStatus,
        'assignedServiceIDs': selectedEmpType == 'handyman'
            ? selectedServices.keys.toList()
            : [],
        if (selectedEmpType == 'handyman') 'handymanBio': bioController.text,
      };

      String? newPicName;
      if (newProfileImage != null) {
        newPicName = newProfileImage!.path.split('/').last;
      }

      await controller.updateEmployee(
        updatedData,
        newProfileImage,
        currentProfilePicName,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      showSuccessDialog(
        context,
        title: 'Employee Updated',
        message: 'The employee has been updated successfully.',
        primaryButtonText: 'OK',
        onPrimary: () async {
          final empID = widget.employee['empID'] as String;

          final updatedData = await controller.reloadEmployeeData(empID);

          if (updatedData != null && mounted) {
            setState(() {
              widget.employee.clear();
              widget.employee.addAll(updatedData);
            });
          }
          widget.onEmployeeUpdated();
          if (mounted) {
            Navigator.of(context)
              ..pop() // close success dialog
              ..pop(); // close edit screen
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      showErrorDialog(context, title: 'Update Failed', message: e.toString());
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
          'Edit Employee',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                    // --- Profile Picture ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage: (newProfileImage != null)
                                ? FileImage(newProfileImage!)
                                : currentProfilePicName.getImageProvider(),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
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

                    // --- Employee ID ---
                    buildLabel('Employee ID'),
                    buildTextFormField(
                      controller: empIDController,
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // --- Employee Type ---
                    buildLabel('Employee Type'),
                    CustomDropdownSingle(
                      value: selectedEmpType,
                      items: const ['admin', 'handyman'],
                      hint: 'Select type',
                      onChanged: (value) {
                        setState(() => selectedEmpType = value!);
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select a type' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Employee Name ---
                    buildLabel('Employee Name'),
                    buildTextFormField(
                      controller: nameController,
                      validator: (value) => Validator.validateName(value),
                    ),
                    const SizedBox(height: 16),

                    // --- Gender ---
                    buildLabel('Gender'),
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
                    const SizedBox(height: 16),

                    // --- Contact Number ---
                    buildLabel('Contact Number'),
                    buildTextFormField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      validator: (value) => Validator.validateContact(value),
                    ),
                    const SizedBox(height: 16),

                    // --- Email Address ---
                    buildLabel('Email Address'),
                    buildTextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => Validator.validateEmail(value),
                    ),
                    const SizedBox(height: 16),

                    // --- Handyman Bio ---
                    if (selectedEmpType == 'handyman') ...[
                      buildLabel('Handyman Bio'),
                      buildTextFormField(
                        controller: bioController,
                        maxLines: 4,
                        hint: 'Enter handyman bio',
                        validator: (value) =>
                            Validator.validateNotEmpty(value, 'Handyman bio'),
                      ),
                      const SizedBox(height: 16),

                      // --- Service Assigned (Conditional) ---
                      buildLabel('Service Assigned'),
                      FutureBuilder<Map<String, String>>(
                        future: servicesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Text(
                              'Failed to load services',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                          return CustomDropdownMulti(
                            key: servicesDropdownKey,
                            allItems: snapshot.data!,
                            selectedItems: selectedServices,
                            hint: 'Select services (multiple)',
                            showSubtitle: false,
                            onChanged: (selected) {
                              setState(() => selectedServices = selected);
                            },
                            validator: (map) =>
                                map!.isEmpty ? 'Select at least one' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- Employee Rating ---
                    if (selectedEmpType == 'handyman') ...[
                      buildLabel('Handyman Rating'),
                      buildTextFormField(
                        controller: TextEditingController(
                          text: handymanRating == null || handymanRating == 0.0
                              ? 'No ratings yet'
                              : '${handymanRating!.toStringAsFixed(1)} ⭐',
                        ),
                        readOnly: true,
                        enabled: false,
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
                      hint: 'Select status',
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select a status' : null,
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

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
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
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }
}
