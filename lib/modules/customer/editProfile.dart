import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/user.dart';
import '../../service/image_service.dart';
import '../../shared/helper.dart';

enum Gender { male, female }

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final Gender initialGender;
  final String initialPhoneNumber;
  final String? initialUserPicName;
  final String userID;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialGender,
    required this.initialPhoneNumber,
    this.initialUserPicName,
    required this.userID,
  });

  @override
  State<EditProfileScreen> createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen>
    with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  Gender? genderItem;
  bool isLoading = false;
  bool isEmailVerified = true;
  bool isVerificationEmailSent = false;
  Timer? verificationTimer;
  String? originalEmail;
  String? originalContact;
  String? emailError;
  String? phoneError;
  String? verificationToken;

  late UserController userController;
  final ImagePicker picker = ImagePicker();
  String? uploadedImageUrl;
  File? newProfileImage;
  String? currentProfilePicName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userController = UserController(
      showErrorSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );

    String initialPhone = widget.initialPhoneNumber;
    String localNumber = initialPhone.startsWith('+60')
        ? '0${initialPhone.substring(3)}'
        : initialPhone;

    nameController.text = widget.initialName;
    emailController.text = widget.initialEmail;
    phoneController.text = localNumber;
    genderItem = widget.initialGender;
    originalEmail = widget.initialEmail.toLowerCase();
    originalContact = widget.initialPhoneNumber;
    isEmailVerified = true;
    currentProfilePicName = widget.initialUserPicName;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    verificationTimer?.cancel();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    userController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isVerificationEmailSent) {
      checkEmailVerification();
    }
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

  Future<void> sendVerificationEmail() async {
    if (Validator.validateEmail(emailController.text.trim()) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = await userController.sendEmailChangeVerification(
        userID: widget.userID,
        newEmail: emailController.text.trim(),
        userName: nameController.text.trim(),
      );

      if (token != null) {
        setState(() {
          verificationToken = token;
          isVerificationEmailSent = true;
          emailError =
              'Verification email sent. Check your inbox and click the link.';
        });
        startVerificationTimer();
      }
    } catch (e) {
      setState(() {
        isVerificationEmailSent = false;
        emailError = 'Failed to send verification email. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void startVerificationTimer() {
    verificationTimer?.cancel();
    verificationTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      await checkEmailVerification();
    });
  }

  Future<void> checkEmailVerification() async {
    if (verificationToken == null) return;

    try {
      final result = await userController.checkEmailVerification(
        verificationToken!,
      );

      if (result['verified'] == true) {
        verificationTimer?.cancel();

        // Update Firebase Auth email (creates new auth account)
        final newEmail = result['new_email'];
        final authUpdateSuccess = await userController.updateFirebaseAuthEmail(
          newEmail: newEmail,
          currentEmail: originalEmail!,
          context: context,
        );

        if (authUpdateSuccess && mounted) {
          setState(() {
            isEmailVerified = true;
            isVerificationEmailSent = false;
            originalEmail = newEmail.toLowerCase();
            emailError = null;
            emailController.text = newEmail;
            verificationToken = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email successfully verified and updated!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (!authUpdateSuccess && mounted) {
          // User cancelled or error occurred
          setState(() {
            isVerificationEmailSent = false;
            emailError = 'Email change was not completed. Please try again.';
            verificationToken = null;
          });
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
      if (e.toString().contains('expired')) {
        verificationTimer?.cancel();
        if (mounted) {
          setState(() {
            isVerificationEmailSent = false;
            emailError = 'Verification link expired. Please resend.';
            verificationToken = null;
          });
        }
      }
    }
  }

  Future<void> submitProfile() async {
    if (emailController.text.trim().toLowerCase() != originalEmail &&
        !isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please verify your new email address before submitting.',
          ),
        ),
      );
      return;
    }

    if (formKey.currentState!.validate()) {
      showLoadingDialog(context, 'Updating profile...');

      try {
        await userController.updateProfile(
          userID: widget.userID,
          name: nameController.text.trim(),
          email: emailController.text.trim().toLowerCase(),
          gender: genderItem == Gender.male ? 'M' : 'F',
          contact: phoneController.text.trim(),
          newImageFile: newProfileImage,
          oldImageUrl: currentProfilePicName,
          setState: setState,
          context: context,
          userType: 'customer',
        );

        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        if (mounted) {
          showSuccessDialog(
            context,
            title: "Successful",
            message: "Your profile has been updated successfully.",
            onPrimary: () {
              Navigator.of(context).pop(); // Close loading dialog
              Navigator.of(context).pop(); // Close success dialog
              Navigator.of(context).pop(); // Close edit screen
            },
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        if (mounted) {
          showErrorDialog(
            context,
            title: "Error",
            message: "Failed to update profile. Please try again.",
            onPressed: () => Navigator.of(context).pop(),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEmailChanged =
        emailController.text.trim().toLowerCase() != originalEmail;
    bool canSubmit = !isEmailChanged || (isEmailChanged && isEmailVerified);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
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
                        backgroundImage: newProfileImage != null
                            ? FileImage(newProfileImage!) as ImageProvider
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
                const SizedBox(height: 50),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                    errorMaxLines: 3,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                  validator: Validator.validateName,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.grey,
                    ),
                    suffixIcon: isEmailChanged
                        ? isEmailVerified
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : IconButton(
                                  tooltip: 'Send verification email',
                                  icon: Icon(
                                    isVerificationEmailSent
                                        ? Icons.hourglass_top
                                        : Icons.send,
                                    color: Colors.orange,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : sendVerificationEmail,
                                )
                        : const Icon(Icons.check_circle, color: Colors.green),
                    errorMaxLines: 3,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: Theme.of(context).textTheme.bodySmall,
                  onChanged: (value) async {
                    final newEmail = value.trim().toLowerCase();
                    final isChanged = newEmail != originalEmail;

                    setState(() {
                      emailError = null;
                      isEmailVerified = !isChanged;
                      isVerificationEmailSent = false;
                      verificationTimer?.cancel();
                      verificationToken = null;
                    });

                    if (isChanged && Validator.validateEmail(value) == null) {
                      bool taken = await userController.isEmailTaken(
                        newEmail,
                        widget.userID,
                      );
                      if (mounted && taken) {
                        setState(() {
                          emailError = 'This email is already registered';
                        });
                      } else if (mounted) {
                        setState(() {
                          emailError =
                              'Click the send icon to verify new email';
                        });
                      }
                    }
                  },
                  validator: Validator.validateEmail,
                ),
                if (emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      emailError!,
                      style: TextStyle(
                        color:
                            emailError!.contains('verify') ||
                                emailError!.contains('sent')
                            ? Colors.orange
                            : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                Text(
                  'Gender',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Radio<Gender>(
                            value: Gender.male,
                            groupValue: genderItem,
                            onChanged: (value) =>
                                setState(() => genderItem = value),
                          ),
                          const Text('Male'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Radio<Gender>(
                            value: Gender.female,
                            groupValue: genderItem,
                            onChanged: (value) =>
                                setState(() => genderItem = value),
                          ),
                          const Text('Female'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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
                    setState(() {
                      phoneError = null;
                    });
                    if (Validator.validateContact(value) == null) {
                      String contact = value.trim();
                      if (contact != originalContact) {
                        bool taken = await userController.isPhoneTaken(
                          contact,
                          widget.userID,
                        );
                        if (taken) {
                          setState(() {
                            phoneError =
                                'This phone number is already registered';
                          });
                        }
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
                const SizedBox(height: 50),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading || !canSubmit
                            ? null
                            : submitProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          disabledBackgroundColor: Colors.orange.shade200,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit',
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
      ),
    );
  }
}
