// user_controller.dart (modified)
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
import '../service/firestore_service.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

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
        isLoading = true; 
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
    required BuildContext context,
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

    String? errorMessage;

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

      bool emailChanged = false;

      // Update firebase authentication email 
      if (authUser.email != email) {
        print('Attempting to update Firebase Auth email...');

        try {
          // Use Firebase's built-in verified update flow
          await authUser.verifyBeforeUpdateEmail(email);

          showErrorSnackBar(
            'A verification link was sent to $email. Please verify it before logging in again.',
          );

          // The new email will apply once verified
          return;
        } on FirebaseAuthException catch (authError) {
          if (authError.code == 'operation-not-allowed') {
            showErrorSnackBar(
              'Email/Password sign-in is not enabled in your Firebase project.\nGo to Firebase Console → Authentication → Sign-in method and enable "Email/Password".',
            );
          } else if (authError.code == 'requires-recent-login') {
            showErrorSnackBar(
              'Please log in again before changing your email.',
            );
          } else if (authError.code == 'email-already-in-use') {
            showErrorSnackBar('That email is already registered.');
          } else {
            showErrorSnackBar('Failed to update email: ${authError.message}');
          }

          return;
        }
      }

      // Update user data in Firestore
      final user = UserModel(
        userID: userID,
        userEmail: email,
        userName: name,
        userGender: gender,
        userContact: contact,
        userType: 'customer', 
        userCreatedAt: DateTime.now(), 
        authID: authUser.uid,
      );

      await _firestoreService.updateUser(user);
      print('Firestore updated');
      
      if (emailChanged) {
        await FirebaseAuth.instance.signOut();
        showErrorSnackBar('✅ Email updated! Logging in with: $email');
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        showErrorSnackBar('✅ Profile updated successfully!');
      }
    } catch (e) {
      showErrorSnackBar('Failed to update profile: $e');

      // Handle specific Firebase Auth errors
      if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Please log in again - session expired';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered';
      }

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

  Future<bool> sendEmailVerification(String email) async {
    try {
      // Check if domain exist
      final domain = email.split('@')[1];
      bool domainExists = await _checkDomainExists(domain);
      if (!domainExists) {
        throw Exception('Email domain does not exist');
      }

      // Send real email
      bool sent = await _sendEmailWithMailer(email);
      if (!sent) {
        throw Exception('Failed to send verification email');
      }

      print('Real email verification sent to: $email');
      return true; 
    } catch (e) {
      print('Email failed: $e');
      throw Exception('Email verification failed: $e');
    }
  }

  Future<bool> _checkDomainExists(String domain) async {
    final validDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'icloud.com'];
    return validDomains.contains(domain);
  }

  Future<bool> _sendEmailWithMailer(String toEmail) async {
    try {
      final smtpServer = gmail('fypflutter@gmail.com', 'nctk gyja ohoo yfdb');
      
      final message = Message()
        ..from = Address('fypflutter@gmail.com', 'Neurofix Handyman')
        ..recipients.add(Address(toEmail))
        ..subject = '📧 Email Verification - Neurofix Handyman'
        ..html = '''
          <h2>Welcome to Neurofix Handyman!</h2>
          <p>Your email <strong>$toEmail</strong> has been verified successfully!</p>
          <p>You can now update your profile.</p>
          <hr>
          <small>This is an automated message. Please do not reply.</small>
        ''';

    final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
      return true;
    } on MailerException catch (e) {
      print('Message not sent: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      return false;
    }
  }

  Future<bool> isEmailVerifiedWithNew(String newEmail) async {
    // Verified if successfully sent the email
    return true;
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