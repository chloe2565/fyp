import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helper.dart';
import '../login.dart';
import '../model/customer.dart';
import '../model/user.dart';
import '../modules/customer/register.dart';
import '../service/auth_service.dart';
import '../navigatorBase.dart';
import '../modules/customer/homepage.dart';
import '../service/firestore_service.dart'; // Ensure this path is correct

class UserController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Gender? gender = Gender.male;

  bool isLoading = false;
  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  // Callback function to display a SnackBar
  final Function(String) showErrorSnackBar;

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

  Future<String> _generateUserId() async {
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

  // Login
  Future<void> login(BuildContext context,
      void Function(void Function()) setState) async {
    // Validate form input
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true; // Show loading indicator
      });

      try {
        // Attempt to log in with email and password
        UserModel? user = await _authService.loginWithEmailAndPassword(
          emailController.text.trim().toLowerCase(),
          currentPasswordController.text.trim(),
        );

        if (user != null) {
          // Successfully authenticated and fetched user data from Firestore
          // Store user data for future use (e.g., in a state management solution)
          // For now, navigate based on userType
          print('UserType from Firestore: "${user.userType}"');

          if (user.userType == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (
                  context) => const CustHomepage()), // Customer homepage
            );
          } else if (user.userType == 'employee') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (
                  context) => const CustHomepage()), // Employee homepage
            );
          } else {
            showErrorSnackBar('Invalid user type: ${user.userType}');
          }
        } else {
          showErrorSnackBar('User data not found. Please contact support.');
        }
      } catch (e) {
        // Handle specific Firebase errors or unexpected errors
        showErrorSnackBar(e.toString());
      } finally {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    } else {
      showErrorSnackBar('Please fix the errors in the form before submitting.');
    }
  }

  Future<void> signInWithGoogle(BuildContext context,
      void Function(void Function()) setState) async {
    setState(() {
      isLoading = true;
    });

    try {
      UserModel? user = await _authService.signInWithGoogle();
      if (user != null) {
        if (user.userType == 'customer' || user.userType == 'employee') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AppNavigationBar(
                    currentIndex: 0, // default to Home tab
                    onTap: (index) {
                      // handle navigation when user taps on nav bar
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
  Future<void> register(BuildContext context,
      void Function(void Function()) setState) async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Check for duplicate email and phone before registration
      bool isEmailTaken = await _firestoreService.isEmailTaken(
          emailController.text.trim().toLowerCase(), '');
      if (isEmailTaken) {
        showErrorSnackBar('This email is already registered.');
        return;
      }

      bool isPhoneTaken = await _firestoreService.isPhoneTaken(
          phoneController.text.trim(), '');
      if (isPhoneTaken) {
        showErrorSnackBar('This phone number is already registered.');
        return;
      }

      // 1. Create Firebase Auth account
      final authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: newPasswordController.text.trim(),
      );

      final authID = authResult.user!.uid;

      // 2. Generate custom userID
      final userID = await _generateUserId();

      // 3. Create UserModel
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

      // 4. Save user in Firestore
      await _firestoreService.addUser(user);

      // 5. Also create Customer entry if userType == customer
      if (user.userType == "customer") {
        final customerID = "C${userID.substring(
            1)}"; // e.g. match userID U0001 -> C0001

        final customer = CustomerModel(
          custID: customerID,
          custAddress: "",
          custState: "",
          custStatus: "active",
          userID: user.userID,
        );

        await _firestoreService.addCustomer(customer);
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
        isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> updateProfile({
    required String userID,
    required String name,
    required String email,
    required String gender,
    required String contact,
    required void Function(void Function()) setState,
  }) async {
    if (Validator.validateName(name) != null) {
      showErrorSnackBar(Validator.validateName(name)!);
      return;
    }
    if (Validator.validateEmail(email) != null) {
      showErrorSnackBar(Validator.validateEmail(email)!);
      return;
    }
    if (Validator.validateContact(contact) != null) {
      showErrorSnackBar(Validator.validateContact(contact)!);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check for duplicate email and phone (excluding current user)
      bool isEmailTaken = await _firestoreService.isEmailTaken(email, userID);
      if (isEmailTaken) {
        showErrorSnackBar('This email is already registered.');
        return;
      }

      bool isPhoneTaken = await _firestoreService.isPhoneTaken(contact, userID);
      if (isPhoneTaken) {
        showErrorSnackBar('This phone number is already registered.');
        return;
      }

      User? authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('No user is currently signed in');
      }

      // Update email in Firebase Authentication if it has changed
      if (authUser.email != email) {
        await authUser.updateEmail(email);
      }

      // Update user data in Firestore
      final user = UserModel(
        userID: userID,
        userEmail: email,
        userName: name,
        userGender: gender,
        userContact: contact,
        userType: 'customer', // Preserve existing userType
        userCreatedAt: DateTime.now(), // Preserve or update as needed
        authID: authUser.uid,
      );

      await _firestoreService.updateUser(user);
      showErrorSnackBar('Profile updated successfully');
    } catch (e) {
      showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle password change
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
    required void Function(void Function()) setState,
  }) async {
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty) {
      showErrorSnackBar('All password fields are required');
      return;
    }

    if (newPassword != confirmNewPassword) {
      showErrorSnackBar('New password and confirm password do not match');
      return;
    }

    if (Validator.validatePassword(newPassword) != null) {
      showErrorSnackBar(Validator.validatePassword(newPassword)!);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.changePassword(currentPassword, newPassword);
      showErrorSnackBar('Password changed successfully');
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors with user-friendly messages
      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
          errorMessage = 'Current password is incorrect';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again to change your password';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        default:
          errorMessage = e.message ?? 'Failed to change password';
      }
      showErrorSnackBar(errorMessage);
    } catch (e) {
      // Handle other unexpected errors
      showErrorSnackBar('Failed to change password. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle account deletion
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
      await _authService.deleteAccount(email);
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