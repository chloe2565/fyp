import 'package:flutter/material.dart';

class Validator {
  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Name is required';
    } else if (name.length < 2) {
      return 'Name must be at least 2 characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      return 'Email is required';
    } else if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email format';
    }
    return null;
  }

  static String? validateContact(String? value) {
    final contact = value?.trim() ?? '';
    final contactRegex = RegExp(r'^[0-9]{10,15}$');

    if (contact.isEmpty) {
      return 'Contact number is required';
    } else if (!contactRegex.hasMatch(contact)) {
      return 'Enter a valid contact (10–11 digits)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }

    bool hasMinLength = password.length >= 8;
    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (!hasMinLength || !hasUppercase || !hasLowercase || !hasNumber || !hasSpecialChar) {
      return 'Password must contain at least 8 characters with uppercase, lowercase, number, special characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    } else if (confirmPassword != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}

class Formatter {
  static String formatPhoneNumber(String number) {
    if (!number.startsWith('+6')) {
      number = '+6$number';
    }

    number = number.replaceAll(RegExp(r'[\s-]'), '');

    if (number.length >= 9) {
      String countryCode = number.substring(0, 3);
      String firstPart = number.substring(3, 7);
      String middlePart = number.substring(7, 10);
      String lastPart = number.substring(10);
      return '$countryCode$firstPart-$middlePart $lastPart'.trim();
    }

    return number;
  }
}

void showChangePasswordDialog({
  required BuildContext context,
  required TextEditingController currentPasswordController,
  required TextEditingController newPasswordController,
  required TextEditingController confirmNewPasswordController,
  required VoidCallback onSubmit,
}) {
  final formKey = GlobalKey<FormState>(); 
  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmNewPasswordVisible = false;

  currentPasswordController.clear();
  newPasswordController.clear();
  confirmNewPasswordController.clear();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form( 
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction, 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Center(
                            child: Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -10,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        context: context,
                        label: 'Current Password',
                        hint: 'Enter current password',
                        controller: currentPasswordController,
                        isVisible: isCurrentPasswordVisible,
                        obscureText: true,
                        validator: (value) => value!.isEmpty ? 'Current Password is required' : null,
                        onVisibilityChanged: () {
                          setDialogState(() {
                            isCurrentPasswordVisible = !isCurrentPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildPasswordField(
                        context: context,
                        label: 'New Password',
                        hint: 'Enter new password',
                        controller: newPasswordController,
                        isVisible: isNewPasswordVisible,
                        obscureText: true,
                        validator: Validator.validatePassword,
                        onVisibilityChanged: () {
                          setDialogState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildPasswordField(
                        context: context,
                        label: 'Confirm New Password',
                        hint: 'Confirm new password',
                        controller: confirmNewPasswordController,
                        isVisible: isConfirmNewPasswordVisible,
                        obscureText: true,
                        validator: (value) => Validator.validateConfirmPassword(
                          value, newPasswordController.text),
                        onVisibilityChanged: () {
                          setDialogState(() {
                            isConfirmNewPasswordVisible = !isConfirmNewPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (formKey.currentState?.validate() ?? false) ? onSubmit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFD722E),
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void showDeleteAccountDialog({
  required BuildContext context,
  required TextEditingController emailController,
  required VoidCallback onDelete,
}) {
  final formKey = GlobalKey<FormState>(); 
  emailController.clear();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form( 
                  key: formKey, 
                  autovalidateMode: AutovalidateMode.onUserInteraction, 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildEmailField(
                        context: context,
                        label: 'Email',
                        hint: 'Enter registered email address',
                        controller: emailController,
                        validator: Validator.validateEmail, 
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (formKey.currentState?.validate() ?? false) ? onDelete : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3D3D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildPasswordField({
  required BuildContext context,
  required String label,
  required String hint,
  required TextEditingController controller,
  required bool isVisible,
  required bool obscureText,
  required String? Function(String?)? validator, 
  required VoidCallback onVisibilityChanged,
}) {
  return TextFormField( 
    controller: controller,
    obscureText: obscureText && !isVisible,
    validator: validator, 
    autovalidateMode: AutovalidateMode.onUserInteraction, 
    style: Theme.of(context).textTheme.bodySmall, 
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: const Icon(
        Icons.lock_outline,
        color: Colors.grey,
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 35, 
        minHeight: 0,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.grey,
        ),
        onPressed: onVisibilityChanged,
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Colors.grey, 
        fontWeight: FontWeight.w400,
      ),
      errorMaxLines: 3, 
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFD722E), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    ),
  );
}

Widget _buildEmailField({
  required BuildContext context,
  required String label,
  required String hint,
  required TextEditingController controller,
  String? Function(String?)? validator,
}) {
  return TextFormField( 
    controller: controller,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction, 
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: Colors.grey,
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Colors.grey, 
        fontWeight: FontWeight.w400,
      ),
      errorMaxLines: 3, 
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFD722E), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    ),
  );
}