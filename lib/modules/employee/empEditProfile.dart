import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../shared/helper.dart';

enum Gender { male, female }

class EmpEditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final Gender initialGender;
  final String initialPhoneNumber;
  final String userID;

  const EmpEditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialGender,
    required this.initialPhoneNumber,
    required this.userID,
  });

  @override
  State<EmpEditProfileScreen> createState() => EmpEditProfileScreenState();
}

class EmpEditProfileScreenState extends State<EmpEditProfileScreen>
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

  late UserController userController;

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
      checkEmailUpdate();
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
      await userController.sendUpdateEmailVerification(
        emailController.text.trim(),
      );
      setState(() {
        isVerificationEmailSent = true;
        emailError = 'Verification email sent. Check your new email\'s inbox.';
      });
      startVerificationTimer();
    } catch (e) {
      setState(() {
        isVerificationEmailSent = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void startVerificationTimer() {
    verificationTimer?.cancel();
    verificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      await checkEmailUpdate();
    });
  }

  Future<void> checkEmailUpdate() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user?.email?.toLowerCase() ==
            emailController.text.trim().toLowerCase()) {
          verificationTimer?.cancel();
          if (mounted) {
            setState(() {
              isEmailVerified = true;
              isVerificationEmailSent = false;
              originalEmail = user?.email?.toLowerCase();
              emailError = null;
              emailController.text = user?.email ?? '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Email successfully verified and updated!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'user-token-expired' ||
            e.code == 'invalid-credential' ||
            e.code == 'user-mismatch') {
          verificationTimer?.cancel();
          if (mounted) {
            showReauthDialog();
          }
        }
      }
    }
  }

  void showReauthDialog() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Email Change'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To complete the email update, please enter your password for the new email.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: Validator.validatePassword,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Optionally reset state or log out
              setState(() {
                isVerificationEmailSent = false;
                emailError = 'Verification timed out. Please try again.';
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final newEmail = emailController.text.trim();
                  final credential = EmailAuthProvider.credential(
                    email: newEmail,
                    password: passwordController.text,
                  );
                  await user?.reauthenticateWithCredential(credential);
                  await user?.getIdToken(true);
                  await user?.reload();
                  final updatedUser = FirebaseAuth.instance.currentUser;

                  Navigator.pop(ctx);

                  if (updatedUser?.email?.toLowerCase() ==
                      newEmail.toLowerCase()) {
                    setState(() {
                      isEmailVerified = true;
                      isVerificationEmailSent = false;
                      originalEmail = updatedUser?.email?.toLowerCase();
                      emailError = null;
                      emailController.text = updatedUser?.email ?? '';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Email successfully verified and updated!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Email update not detected. Please try again.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
      setState(() => isLoading = true);

      try {
        await userController.updateProfile(
          userID: widget.userID,
          name: nameController.text.trim(),
          email: emailController.text.trim().toLowerCase(),
          gender: genderItem == Gender.male ? 'M' : 'F',
          contact: phoneController.text.trim(),
          setState: setState,
          context: context,
        );

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
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
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 24,
                ),
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
                            Container(
                              height: 120,
                              width: 120,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                    'assets/images/profile.jpg',
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () =>
                                    debugPrint('Edit profile picture tapped!'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFD722E),
                                    shape: BoxShape.circle,
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
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey,
                          ),
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
                                              : Icons.error_outline,
                                          color: Colors.orange,
                                        ),
                                        onPressed: isLoading
                                            ? null
                                            : sendVerificationEmail,
                                      )
                              : const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
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
                          });

                          if (isChanged &&
                              Validator.validateEmail(value) == null) {
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
                                    'Click the icon to verify new email';
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
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
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
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: Colors.grey,
                          ),
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
                      if (phoneError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            phoneError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
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
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                disabledBackgroundColor: Colors.orange.shade200,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade400,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
            ),
    );
  }
}
