import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/databaseModel.dart';
import '../modules/employee/homepage.dart';
import '../service/auth_service.dart';
import '../service/user.dart';
import '../service/customer.dart';
import '../shared/helper.dart';
import '../shared/custNavigatorBase.dart';
import '../login.dart';
import '../modules/customer/register.dart';
import '../modules/customer/homepage.dart';

class UserController {
  final UserService userService = UserService();
  final CustomerService customerService = CustomerService();
  final AuthService authService = AuthService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Gender? gender = Gender.male;

  bool isLoading = false;
  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  final storage = const FlutterSecureStorage();
  bool rememberMe = false;
  final Function(String) showErrorSnackBar;
  static const String BACKEND_URL = 'https://fyp-backend-738r.onrender.com';

  UserController({required this.showErrorSnackBar});

  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword = !obscureCurrentPassword;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword = !obscureNewPassword;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
  }

  Future<void> loadSavedCredentials() async {
    final String? rememberMeFlag = await storage.read(key: 'remember_me_flag');

    if (rememberMeFlag == 'true') {
      rememberMe = true;
      emailController.text = await storage.read(key: 'remember_me_email') ?? '';
      currentPasswordController.text =
          await storage.read(key: 'remember_me_password') ?? '';
    } else {
      rememberMe = false;
    }
  }

  Future<void> saveCredentials() async {
    await storage.write(key: 'remember_me_flag', value: 'true');
    await storage.write(
      key: 'remember_me_email',
      value: emailController.text.trim(),
    );
    await storage.write(
      key: 'remember_me_password',
      value: currentPasswordController.text.trim(),
    );
  }

  Future<void> clearCredentials() async {
    await storage.write(key: 'remember_me_flag', value: 'false');
    await storage.delete(key: 'remember_me_email');
    await storage.delete(key: 'remember_me_password');
  }

  Future<String> generateUserId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .orderBy('userID', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return "U0001";

    final lastId = snapshot.docs.first['userID'] as String;
    final number = int.parse(lastId.substring(1)) + 1;
    return "U${number.toString().padLeft(4, '0')}";
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        print('No authenticated user found.');
        return null;
      }
      return await userService.getUserByAuthID(authUser.uid);
    } catch (e) {
      showErrorSnackBar('Failed to get user details: $e');
      return null;
    }
  }

  Future<String?> getEmpType(String userID) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Employee')
          .where('userID', isEqualTo: userID)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs.first['empType'] as String?;
    } catch (e) {
      print('Error fetching empType: $e');
      return null;
    }
  }

  // Login
  Future<void> login(
    BuildContext context,
    void Function(void Function()) setState,
  ) async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      try {
        UserModel? user = await authService.loginWithEmailAndPassword(
          emailController.text.trim().toLowerCase(),
          currentPasswordController.text.trim(),
        );

        if (user != null) {
          if (rememberMe) {
            await saveCredentials();
          } else {
            await clearCredentials();
          }

          print('UserType from Firestore: "${user.userType}"');

          if (user.userType == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CustHomepage(),
              ), // Customer homepage
            );
          } else if (user.userType == 'employee') {
            final empType = await getEmpType(user.userID);
            await storage.write(key: 'empType', value: empType ?? 'handyman');

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const EmpHomepage(),
              ), // Employee homepage
            );
          } else {
            showErrorSnackBar('Invalid user type: ${user.userType}');
          }
        } else {
          showErrorSnackBar('User data not found. Please contact support.');
        }
      } catch (e) {
        showErrorSnackBar(e.toString());
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      showErrorSnackBar('Please fix the errors in the form before submitting.');
    }
  }

  Future<void> logout(
    BuildContext context,
    void Function(void Function()) setState,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      await authService.auth.signOut();

      try {
        if (await authService.googleSignIn.isSignedIn()) {
          await authService.googleSignIn.signOut();
        }
      } catch (e) {
        print('Google Sign-Out failed, but continuing logout: $e');
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (context.mounted) {
        showErrorSnackBar('Error logging out: $e');
      }
    } finally {
      if (context.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> signInWithGoogle(
    BuildContext context,
    void Function(void Function()) setState,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      UserModel? user = await authService.signInWithGoogle();
      if (user != null) {
        if (user.userType == 'customer' || user.userType == 'employee') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustNavigationBar(
                currentIndex: 0,
                onTap: (index) {
                  print("Tapped index: $index");
                },
              ),
            ),
          );
        } else {
          showErrorSnackBar('Invalid user type: ${user.userType}');
        }
      } else {
        showErrorSnackBar('Failed to retrieve user data.');
      }
    } catch (e) {
      showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Register new user
  Future<void> register(
    BuildContext context,
    void Function(void Function()) setState,
  ) async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      bool isEmailTaken = await userService.isEmailTaken(
        emailController.text.trim().toLowerCase(),
        '',
      );
      if (isEmailTaken) {
        showErrorSnackBar('This email is already registered.');
        return;
      }

      bool isPhoneTaken = await userService.isPhoneTaken(
        phoneController.text.trim(),
        '',
      );
      if (isPhoneTaken) {
        showErrorSnackBar('This phone number is already registered.');
        return;
      }

      final authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: newPasswordController.text.trim(),
          );

      final authID = authResult.user!.uid;
      final userID = await generateUserId();

      final user = UserModel(
        userID: userID,
        userEmail: emailController.text.trim().toLowerCase(),
        userName: nameController.text.trim(),
        userGender: gender == Gender.male ? "M" : "F",
        userContact: phoneController.text.trim(),
        userType: "customer",
        userCreatedAt: DateTime.now(),
        authID: authID,
      );

      await userService.addUser(user);

      if (user.userType == "customer") {
        final customerID = "C${userID.substring(1)}";

        final customer = CustomerModel(
          custID: customerID,
          custAddress: "",
          custState: "",
          custStatus: "active",
          userID: user.userID,
        );

        await customerService.addCustomer(customer);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      showErrorSnackBar("Auth error: ${e.message}");
    } catch (e) {
      showErrorSnackBar("Unexpected error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> sendEmailChangeVerification({
    required String userID,
    required String newEmail,
    required String userName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BACKEND_URL/send-email-change-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userID,
          'new_email': newEmail,
          'user_name': userName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['token'];
        } else {
          throw Exception(
            data['message'] ?? 'Failed to send verification email',
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error');
      }
    } catch (e) {
      showErrorSnackBar('Error sending verification email: $e');
      rethrow;
    }
  }

  /// Check if email verification link has been clicked
  Future<Map<String, dynamic>> checkEmailVerification(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$BACKEND_URL/check-email-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          return {
            'verified': true,
            'new_email': data['new_email'],
            'user_id': data['user_id'],
          };
        } else if (data['status'] == 'pending') {
          return {'verified': false};
        }
      }
      throw Exception(data['message'] ?? 'Verification check failed');
    } catch (e) {
      if (e.toString().contains('expired')) {
        throw Exception('expired');
      }
      rethrow;
    }
  }

  Future<bool> updateFirebaseAuthEmail({
    required String newEmail,
    required String currentEmail,
    required BuildContext context,
  }) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool success = false;
    bool obscurePassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Center(
              child: Text(
                'Confirm Email Change',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please enter current password to confirm:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    enabled: true,
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,

            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false))
                          return;
                        showLoadingDialog(context, 'Updating email...');

                        try {
                          User? currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) {
                            throw Exception('No user signed in');
                          }

                          String password = passwordController.text.trim();
                          String oldAuthID = currentUser.uid;

                          // Re-authenticate with current credentials to verify password
                          final currentCredential =
                              EmailAuthProvider.credential(
                                email: currentEmail,
                                password: password,
                              );
                          await currentUser.reauthenticateWithCredential(
                            currentCredential,
                          );

                          // Sign out current user
                          await FirebaseAuth.instance.signOut();

                          // Create new auth account with new email
                          UserCredential newUserCredential = await FirebaseAuth
                              .instance
                              .createUserWithEmailAndPassword(
                                email: newEmail,
                                password: password,
                              );

                          String newAuthID = newUserCredential.user!.uid;

                          // Update Firestore User document with new authID
                          await FirebaseFirestore.instance
                              .collection('User')
                              .where('authID', isEqualTo: oldAuthID)
                              .get()
                              .then((snapshot) async {
                                if (snapshot.docs.isNotEmpty) {
                                  String userDocID = snapshot.docs.first.id;
                                  await FirebaseFirestore.instance
                                      .collection('User')
                                      .doc(userDocID)
                                      .update({
                                        'authID': newAuthID,
                                        'userEmail': newEmail,
                                      });
                                }
                              });

                          // Delete old auth account
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                                email: currentEmail,
                                password: password,
                              );
                          User? oldUser = FirebaseAuth.instance.currentUser;
                          await oldUser?.delete();

                          // Sign back in with new credentials
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                                email: newEmail,
                                password: password,
                              );

                          success = true;

                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(ctx); // Close email update dialog
                        } on FirebaseAuthException catch (e) {
                          Navigator.pop(context); // Close loading dialog

                          String errorMessage = 'Authentication failed';
                          if (e.code == 'wrong-password' ||
                              e.code == 'invalid-credential') {
                            errorMessage = 'Incorrect password';
                          } else if (e.code == 'email-already-in-use') {
                            errorMessage = 'This email is already in use';
                          } else if (e.code == 'too-many-requests') {
                            errorMessage =
                                'Too many attempts. Please try again later';
                          } else {
                            errorMessage =
                                e.message ?? 'Unknown error occurred';
                          }

                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } catch (e) {
                          Navigator.pop(context); // Close loading dialog

                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    passwordController.dispose();
    return success;
  }

  Future<bool> isEmailTaken(String email, String excludeUserID) async {
    try {
      return userService.isEmailTaken(email, excludeUserID);
    } catch (e) {
      showErrorSnackBar(e.toString());
      return true;
    }
  }

  Future<bool> isPhoneTaken(String phone, String excludeUserID) async {
    try {
      return userService.isPhoneTaken(phone, excludeUserID);
    } catch (e) {
      showErrorSnackBar(e.toString());
      return true;
    }
  }

  Future<void> updateProfile({
    required String userID,
    required String name,
    required String email,
    required String gender,
    required String contact,
    String? newPicName,
    required void Function(void Function()) setState,
    required BuildContext context,
    required String userType,
  }) async {
    if (Validator.validateName(name) != null) {
      showErrorSnackBar(Validator.validateName(name)!);
      return;
    }
    if (userType == 'customer') {
      if (email.isEmpty) {
        showErrorSnackBar('Email address is required.');
        return;
      }
      if (Validator.validateEmail(email) != null) {
        showErrorSnackBar(Validator.validateEmail(email)!);
        return;
      }
    }
    if (Validator.validateContact(contact) != null) {
      showErrorSnackBar(Validator.validateContact(contact)!);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool isPhoneTaken = await userService.isPhoneTaken(contact, userID);
      if (isPhoneTaken) {
        showErrorSnackBar('This phone number is already registered.');
        return;
      }

      User? authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('No user is currently signed in');
      }

      final Map<String, dynamic> userUpdates = {
        'userName': name,
        'userGender': gender,
        'userContact': contact,
      };

      // Only update email if it's a customer
      if (userType == 'customer') {
        userUpdates['userEmail'] = email;
      }

      // Only update the picture if a new one was provided
      if (newPicName != null) {
        userUpdates['userPicName'] = newPicName;
      }

      await userService.updateUser(userID, userUpdates);
      print('Firestore profile data updated successfully.');

      showSuccessDialog(
        context,
        title: 'Successful',
        message: 'Your profile has been successfully updated.',
        primaryButtonText: 'OK',
        onPrimary: () {
          Navigator.of(context).pop(); // Close success dialog
        },
      );
    } catch (e) {
      showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle password change
  Future<String?> changePassword({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
    required void Function(void Function()) setState,
  }) async {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmNewPassword.isEmpty) {
      return 'All password fields are required';
    }

    if (newPassword != confirmNewPassword) {
      return 'New password and confirm password do not match';
    }

    if (Validator.validatePassword(newPassword) != null) {
      return Validator.validatePassword(newPassword);
    }

    setState(() => isLoading = true);
    showLoadingDialog(context, 'Updating your password...');

    try {
      await authService.changePassword(currentPassword, newPassword);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close change password popup

        showSuccessDialog(
          context,
          title: 'Successful',
          message: 'Your password has been successfully updated.',
          primaryButtonText: 'OK',
          onPrimary: () {
            Navigator.of(context).pop(); // Close success dialog
          },
        );
      }
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      return null;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // Close loading dialog
      switch (e.code) {
        case 'invalid-credential':
          return 'Current password is incorrect';
        case 'requires-recent-login':
          return 'Please log in again to change your password';
        case 'weak-password':
          return 'New password is too weak';
        default:
          return e.message ?? 'Failed to change password';
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // Close loading dialog
      return 'Something went wrong. Please try again later.';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle account deactivation
  Future<void> deleteAccount({
    required String email,
    required void Function(void Function()) setState,
  }) async {
    if (email.isEmpty) {
      showErrorSnackBar('Email is required');
      return;
    }

    if (Validator.validateEmail(email) != null) {
      showErrorSnackBar(Validator.validateEmail(email)!);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.deleteAccount(email);
      showErrorSnackBar('Account deleted successfully');
    } catch (e) {
      showErrorSnackBar('Failed to delete account: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}
