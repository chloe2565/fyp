import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fyp/service/image_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/user.dart';
import '../../shared/helper.dart';

enum Gender { male, female }

class EmpEditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final Gender initialGender;
  final String initialPhoneNumber;
  final String? initialUserPicName;
  final String userID;
  final String empID;
  final String empType;
  final String empStatus;
  final List<String> serviceAssigned;
  final VoidCallback onProfileUpdated;

  const EmpEditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialGender,
    required this.initialPhoneNumber,
    this.initialUserPicName,
    required this.userID,
    required this.empID,
    required this.empType,
    required this.empStatus,
    this.serviceAssigned = const [],
    required this.onProfileUpdated,
  });

  @override
  State<EmpEditProfileScreen> createState() => EmpEditProfileScreenState();
}

class EmpEditProfileScreenState extends State<EmpEditProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  Gender? genderItem;
  bool isLoading = false;
  String? phoneError;

  late UserController userController;
  final ImagePicker picker = ImagePicker();
  File? newProfileImage;
  String? currentProfilePicName;

  @override
  void initState() {
    super.initState();

    userController = UserController(
      showErrorSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );

    nameController.text = widget.initialName;
    phoneController.text = widget.initialPhoneNumber.startsWith('+60')
        ? '0${widget.initialPhoneNumber.substring(3)}'
        : widget.initialPhoneNumber;
    genderItem = widget.initialGender;
    currentProfilePicName = widget.initialUserPicName;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    userController.dispose();
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

  Future<void> submitProfile() async {
    if (!formKey.currentState!.validate()) return;

    showLoadingDialog(context, 'Updating profile...');
    
    try {
      await userController.updateProfile(
        userID: widget.userID,
        name: nameController.text.trim(),
        email: widget.initialEmail,
        gender: genderItem == Gender.male ? 'M' : 'F',
        contact: phoneController.text.trim(),
        newImageFile: newProfileImage,
        oldImageUrl: currentProfilePicName,
        setState: setState,
        context: context,
        userType: 'employee',
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      if (mounted) {
        showSuccessDialog(
          context,
          title: "Successful",
          message: "Your profile has been updated successfully.",
          onPrimary: () {
            widget.onProfileUpdated();
            Navigator.of(context).pop(); // Close success
            Navigator.of(context).pop(); // Close edit screen
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      if (mounted) {
        showErrorDialog(
          context,
          title: "Error",
          message: "Failed to update profile. Please try again.",
          onPressed: () => Navigator.of(context).pop(), // Close error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHandyman = widget.empType == 'handyman';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(width: 2, color: Colors.white),
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
              const SizedBox(height: 40),

              // Employee ID
              // TextFormField(
              //   enabled: false,
              //   initialValue: widget.empID,
              //   decoration: const InputDecoration(
              //     labelText: 'Employee ID',
              //     prefixIcon: Icon(Icons.people_outlined, color: Colors.grey),
              //   ),
              //   style: Theme.of(context).textTheme.bodySmall,
              // ),
              // const SizedBox(height: 24),

              // Employee Type
              TextFormField(
                enabled: false,
                initialValue: capitalizeFirst(widget.empType),
                decoration: const InputDecoration(
                  labelText: 'Employee Type',
                  prefixIcon: Icon(Icons.work_outline, color: Colors.grey),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Employee Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Employee Name',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                  errorMaxLines: 3,
                ),
                style: Theme.of(context).textTheme.bodySmall,
                validator: Validator.validateName,
              ),
              const SizedBox(height: 24),

              // Employee Gender
              Text(
                'Gender',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<Gender>(
                      value: Gender.male,
                      groupValue: genderItem,
                      title: const Text('Male'),
                      dense: true,
                      onChanged: (value) => setState(() => genderItem = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<Gender>(
                      value: Gender.female,
                      groupValue: genderItem,
                      title: const Text('Female'),
                      dense: true,
                      onChanged: (value) => setState(() => genderItem = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Employee Contact Number
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey),
                  errorMaxLines: 3,
                ),
                keyboardType: TextInputType.phone,
                style: Theme.of(context).textTheme.bodySmall,
                onChanged: (value) async {
                  setState(() => phoneError = null);
                  if (Validator.validateContact(value) == null) {
                    bool taken = await userController.isPhoneTaken(
                      value.trim(),
                      widget.userID,
                    );
                    if (taken) {
                      setState(() {
                        phoneError = 'This phone number is already registered';
                      });
                    }
                  }
                },
                validator: (value) {
                  final error = Validator.validateContact(value);
                  if (error != null) return error;
                  if (phoneError != null) return phoneError;
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Email
              TextFormField(
                enabled: false,
                initialValue: widget.initialEmail,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Employee Services Assigned
              if (isHandyman) ...[
                TextFormField(
                  enabled: false,
                  initialValue: widget.serviceAssigned.isNotEmpty
                      ? widget.serviceAssigned.join(', ')
                      : 'No services assigned',

                  decoration: const InputDecoration(
                    labelText: 'Service Assigned',
                    prefixIcon: Icon(
                      Icons.home_repair_service_outlined,
                      color: Colors.grey,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: null,
                ),
                const SizedBox(height: 24),
              ],

              // Employee Status
              TextFormField(
                enabled: false,
                initialValue: capitalizeFirst(widget.empStatus),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.work_outline, color: Colors.grey),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        disabledBackgroundColor: Colors.orange.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
}
