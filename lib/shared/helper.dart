import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp/service/image_service.dart';
import 'package:intl/intl.dart';
import '../controller/ratingReview.dart';
import '../controller/serviceRequest.dart';
import '../model/databaseModel.dart';
import '../model/reviewDisplayViewModel.dart';

class Validator {
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

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
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (email.isEmpty) {
      return 'Email is required';
    } else if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email format';
    }
    return null;
  }

  static String? validateContact(String? value) {
    final contact = value?.trim() ?? '';
    final contactRegex = RegExp(r'^[0-9]{10,11}$');

    if (contact.isEmpty) {
      return 'Contact number is required';
    } else if (!contactRegex.hasMatch(contact)) {
      return 'Enter a valid contact (10–11 digits)';
    }
    return null;
  }

  static String? validateSalary(String? value) {
    final salary = value?.trim() ?? '';

    if (salary.isEmpty) {
      return 'Salary is required';
    }

    if (salary.startsWith('0') && !salary.startsWith('0.')) {
      return 'Salary cannot start with 0';
    }

    final salaryValue = double.tryParse(salary);

    if (salaryValue == null) {
      return 'Please enter a valid number';
    }

    if (salaryValue <= 0) {
      return 'Salary must be greater than 0';
    }

    if (salaryValue > 999999.99) {
      return 'Salary exceeds maximum allowed';
    }

    if (salary.contains('.')) {
      final parts = salary.split('.');
      if (parts[1].length > 2) {
        return 'Maximum 2 decimal places allowed';
      }
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

    if (!hasMinLength ||
        !hasUppercase ||
        !hasLowercase ||
        !hasNumber ||
        !hasSpecialChar) {
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

  static String? validateDuration(String? minStr, String? maxStr) {
    if (minStr == null || minStr.isEmpty) return 'Min required';
    if (maxStr == null || maxStr.isEmpty) return 'Max required';

    final min = int.tryParse(minStr);
    final max = int.tryParse(maxStr);

    if (min == null || max == null) return 'Must be whole numbers';
    if (min <= 0 || max <= 0) return 'Must be greater than 0';
    if (max < min) return 'Max must be ≥ Min';

    return null;
  }

  static String? validatePhoto(List<File> photos) {
    if (photos.isEmpty) {
      return 'At least one photo is required';
    }
    return null;
  }

  static String? validatePriceRange({
    required String? minText,
    required String? maxText,
    required bool isMinField,
  }) {
    final min = double.tryParse(minText ?? '');
    final max = double.tryParse(maxText ?? '');

    if (isMinField) {
      if (minText == null || minText.isEmpty) return null;
      if (min == null) return 'Enter a valid number';
      if (min < 0) return 'Minimum cannot be negative';
      if (max != null && min > max) return 'Min cannot exceed max';
    }

    if (!isMinField) {
      if (maxText == null || maxText.isEmpty) return null;
      if (max == null) return 'Enter a valid number';
      if (max < 0) return 'Maximum cannot be negative';

      // If min is 0 → max cannot be 0
      if (min == 0 && max == 0) {
        return 'Max cannot be 0 if min is 0';
      }
    }
    return null;
  }

  static DateRangeValidation validateDateRange({
    DateTime? startDate,
    DateTime? endDate,
    bool allowFutureDates = false,
  }) {
    String? startError;
    String? endError;
    if (startDate == null && endDate == null) {
      return DateRangeValidation();
    }

    // Validate start date
    if (startDate == null) {
      startError = 'Date is required';
    } else if (!allowFutureDates) {
      final today = DateUtils.dateOnly(DateTime.now());
      final start = DateUtils.dateOnly(startDate);
      if (start.isAfter(today)) {
        startError = 'Start date cannot be in the future';
      }
    }

    // Validate end date
    if (endDate == null) {
      endError = 'Date is required';
    } else if (!allowFutureDates) {
      final today = DateUtils.dateOnly(DateTime.now());
      final end = DateUtils.dateOnly(endDate);
      if (end.isAfter(today)) {
        endError = 'End date cannot be in the future';
      }
    }

    // End date cannot be earlier than start date
    if (startDate != null && endDate != null) {
      final start = DateUtils.dateOnly(startDate);
      final end = DateUtils.dateOnly(endDate);

      if (end.isBefore(start)) {
        endError = 'End date cannot be earlier than start date';
      }
    }

    return DateRangeValidation(
      startDateError: startError,
      endDateError: endError,
    );
  }

  static bool isValidDateRange({
    DateTime? startDate,
    DateTime? endDate,
    bool allowFutureDates = false,
  }) {
    return validateDateRange(
      startDate: startDate,
      endDate: endDate,
      allowFutureDates: allowFutureDates,
    ).isValid;
  }

  static String? validateRatingRange({
    required String? minText,
    required String? maxText,
    required bool isMinField,
  }) {
    final min = double.tryParse(minText ?? '');
    final max = double.tryParse(maxText ?? '');

    if (isMinField) {
      if (minText == null || minText.isEmpty) return null;
      if (min == null) return 'Enter a valid number';
      if (min < 0 || min > 5) return 'Rating must be 0.0 - 5.0';
      if (max != null && min > max) return 'Min cannot exceed max';
    } else {
      if (maxText == null || maxText.isEmpty) return null;
      if (max == null) return 'Enter a valid number';
      if (max < 0 || max > 5) return 'Rating must be 0.0 - 5.0';
      if (min != null && max < min) return 'Max cannot be less than min';
    }

    return null;
  }

  static String? validateDateTimeRange({
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String fieldName,
  }) {
    if (endDateTime.isBefore(startDateTime)) {
      return 'End must be after start';
    }

    const minDuration = Duration(minutes: 5);
    if (endDateTime.difference(startDateTime).isNegative ||
        endDateTime.difference(startDateTime) < minDuration) {
      return 'Unavailable period must be at least ${minDuration.inMinutes} minutes.';
    }
    return null;
  }

  static String? validateSelectedDateTime(
    DateTime? dateTime,
    TimeOfDay? timeOfDay,
    String fieldName,
  ) {
    if (dateTime == null || timeOfDay == null) {
      return '$fieldName is required';
    }
    return null;
  }
}

class DateRangeValidation {
  final String? startDateError;
  final String? endDateError;
  final bool isValid;

  DateRangeValidation({this.startDateError, this.endDateError})
    : isValid = startDateError == null && endDateError == null;
}

class Formatter {
  static String formatPhoneNumber(String number) {
    if (!number.startsWith('+6')) {
      number = '+6$number';
    }

    number = number.replaceAll(RegExp(r'[\s-]'), '');

    if (number.length >= 12) {
      String countryCode = number.substring(0, 3);
      String firstPart = number.substring(3, 5);
      String middlePart = number.substring(5, 8);
      String lastPart = number.substring(8);
      return '$countryCode$firstPart-$middlePart $lastPart'.trim();
    }

    return number;
  }

  static String formatGender(String? genderCode) {
    if (genderCode == 'M') return 'Male';
    if (genderCode == 'F') return 'Female';
    return 'N/A';
  }

  static String formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return '';

    final format = DateFormat('dd MMM yyyy');

    if (startDate != null && endDate != null) {
      if (DateUtils.isSameDay(startDate, endDate)) {
        return format.format(startDate);
      }
      return '${format.format(startDate)} - ${format.format(endDate)}';
    } else if (startDate != null) {
      return 'From ${format.format(startDate)}';
    } else if (endDate != null) {
      return 'Until ${format.format(endDate)}';
    }

    return '';
  }

  static String formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';

    final format = DateFormat('dd MMM yyyy hh:mm a');
    return format.format(dt);
  }
}

void showChangePasswordDialog({
  required BuildContext context,
  required TextEditingController currentPasswordController,
  required TextEditingController newPasswordController,
  required TextEditingController confirmNewPasswordController,
  required Future<String?> Function() onSubmit,
  String? errorText,
}) {
  final formKey = GlobalKey<FormState>();
  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmNewPasswordVisible = false;
  String? currentPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;

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
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Current Password
                      buildPasswordField(
                        context: context,
                        label: 'Current Password',
                        hint: 'Enter current password',
                        controller: currentPasswordController,
                        isVisible: isCurrentPasswordVisible,
                        obscureText: true,
                        validator: (value) =>
                            currentPasswordError ??
                            (value!.isEmpty
                                ? 'Current Password is required'
                                : null),
                        onVisibilityChanged: () {
                          setDialogState(() {
                            isCurrentPasswordVisible =
                                !isCurrentPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      // New Password
                      buildPasswordField(
                        context: context,
                        label: 'New Password',
                        hint: 'Enter new password',
                        controller: newPasswordController,
                        isVisible: isNewPasswordVisible,
                        obscureText: true,
                        validator: (value) =>
                            newPasswordError ??
                            Validator.validatePassword(value),
                        onVisibilityChanged: () {
                          setDialogState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      // Confirm New Password
                      buildPasswordField(
                        context: context,
                        label: 'Confirm New Password',
                        hint: 'Confirm new password',
                        controller: confirmNewPasswordController,
                        isVisible: isConfirmNewPasswordVisible,
                        obscureText: true,
                        validator: (value) =>
                            confirmPasswordError ??
                            Validator.validateConfirmPassword(
                              value,
                              newPasswordController.text,
                            ),
                        onVisibilityChanged: () {
                          setDialogState(() {
                            isConfirmNewPasswordVisible =
                                !isConfirmNewPasswordVisible;
                          });
                        },
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            setDialogState(() {
                              currentPasswordError = null;
                              newPasswordError = null;
                              confirmPasswordError = null;
                            });

                            if (formKey.currentState?.validate() ?? false) {
                              final error = await onSubmit();

                              if (error != null) {
                                setDialogState(() {
                                  if (error.toLowerCase().contains('current')) {
                                    currentPasswordError = error;
                                  } else if (error.toLowerCase().contains(
                                    'confirm',
                                  )) {
                                    confirmPasswordError = error;
                                  } else if (error.toLowerCase().contains(
                                    'new',
                                  )) {
                                    newPasswordError = error;
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                  }

                                  formKey.currentState?.validate();
                                });
                              }
                            }
                          },

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(flex: 1),
                          const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(flex: 1),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildEmailField(
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
                          onPressed: (formKey.currentState?.validate() ?? false)
                              ? onDelete
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3D3D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Delete Account',
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

Widget buildPasswordField({
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
      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
      prefixIconConstraints: const BoxConstraints(minWidth: 35, minHeight: 0),
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

Widget buildEmailField({
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
    style: Theme.of(context).textTheme.bodySmall,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
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

class ServiceHelper {
  // Get an icon based on the service name
  static IconData getIconForService(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'a/c':
        return Icons.air;
      case 'moving':
        return Icons.local_shipping;
      case 'electric':
        return Icons.electrical_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'toilet':
        return Icons.wc;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'painting':
        return Icons.format_paint;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'carpentry':
        return Icons.carpenter;
      default:
        return Icons.more_horiz;
    }
  }

  // Get a color based on the service name
  static Color getColorForService(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'a/c':
        return const Color(0xFFFFF9C4);
      case 'moving':
        return const Color(0xFF96D6D5);
      case 'electric':
        return const Color(0xFFFFD2AA);
      case 'plumbing':
        return const Color(0xFFAAE8FF);
      case 'toilet':
        return const Color(0xFFAAD0FF);
      case 'laundry':
        return const Color(0xFFF2B5F8);
      case 'painting':
        return const Color(0xFFDFD9FF);
      case 'cleaning':
        return const Color(0xFFC6E3B4);
      case 'carpentry':
        return const Color(0xFFFFBB29);
      default:
        return const Color(0xFFFFA7A7);
    }
  }
}

Widget buildStarRating(double rating, {double starSize = 16}) {
  List<Widget> stars = [];
  for (int i = 1; i <= 5; i++) {
    if (i <= rating) {
      stars.add(
        Icon(Icons.star, color: const Color(0xFFFFC107), size: starSize),
      );
    } else if (i - rating < 1) {
      stars.add(
        Icon(Icons.star_half, color: const Color(0xFFFFC107), size: starSize),
      );
    } else {
      stars.add(
        Icon(Icons.star_border, color: Colors.grey.shade400, size: starSize),
      );
    }
  }
  return Row(children: stars);
}

Widget buildStyledChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 255, 255, 255),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color.fromARGB(255, 229, 228, 228)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
    ),
  );
}

Widget buildReviewTile(ReviewDisplayData reviewData) {
  final review = reviewData.review;
  final authorName = reviewData.authorName;
  final String formattedDate = DateFormat(
    'dd MMM yyyy',
  ).format(review.ratingCreatedAt);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          child: ClipOval(
            child: reviewData.avatarPath.toNetworkImage(
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              buildStarRating(review.ratingNum, starSize: 18),
              const SizedBox(height: 8),
              Text(
                review.ratingText,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildSearchField({
  required BuildContext context,
  String hintText = 'Search here...',
  VoidCallback? onFilterPressed,
  TextEditingController? controller,
  bool hasFilter = false,
  int numberOfFilters = 0,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Container(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasFilter && numberOfFilters > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$numberOfFilters',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.tune),
                color: Colors.orange,
                onPressed: onFilterPressed,
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    ),
  );
}

Widget buildPrimaryTabBar({
  required BuildContext context,
  required List<String> tabs,
  EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 20.0),
}) {
  return Container(
    margin: margin,
    color: Colors.white,
    child: TabBar(
      indicatorColor: Theme.of(context).colorScheme.primary,
      indicatorWeight: 3.0,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.black,
      unselectedLabelStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      labelStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      tabs: tabs
          .map(
            (label) => SizedBox(
              width: MediaQuery.of(context).size.width / (tabs.length * 1.5),
              child: Tab(text: label),
            ),
          )
          .toList(),
    ),
  );
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<MapEntry<String, String>> details;
  final List<Widget>? actions;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.details,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            ...details.map((e) => buildDetailRow(context, e.key, e.value)),
            if (actions != null) ...[
              Row(
                children: actions!.expand((a) sync* {
                  yield Expanded(child: a);
                  if (a != actions!.last) yield const SizedBox(width: 16);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildDetailRow(BuildContext context, String title, String value) {
    final String lowerTitle = title.toLowerCase();
    final bool isStatusRow = lowerTitle.contains('status');
    final bool isAmountRow = lowerTitle == 'amount to pay';

    TextStyle amountStyle =
        Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Theme.of(context).colorScheme.primary,
        ) ??
        const TextStyle();

    final TextStyle defaultStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: isStatusRow ? getStatusColor(value) : Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 2,
            child: isStatusRow
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(value),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: isAmountRow ? amountStyle : defaultStyle,
                  ),
          ),
        ],
      ),
    );
  }
}

String capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

String getStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Pending';
    case 'confirmed':
      return 'Confirmed';
    case 'departed':
      return 'Departed';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    case 'on leave':
      return 'On Leave';
    case 'late':
      return 'Late';
    case 'absent':
      return 'Absent';
    case 'paid':
      return 'Paid';
    case 'active':
      return 'Active';
    case 'inactive':
      return 'Inactive';
    default:
      return 'Unknown';
  }
}

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'on leave':
      return Colors.amber;
    case 'confirmed':
      return Color(0xFFFD722E);
    case 'departed':
    case 'resigned':
    case 'retrired':
      return Colors.blue;
    case 'completed':
    case 'paid':
    case 'active':
      return Colors.green;
    case 'cancelled':
    case 'failed':
    case 'inactive':
    case 'absent':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Color getUrgencyColor(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'urgent':
      return Colors.red;
    case 'high':
      return Colors.orange;
    case 'medium':
      return Colors.blue;
    case 'normal':
      return Colors.green;
    default:
      return Colors.white;
  }
}

Color getUrgencyBgColor(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'urgent':
      return Colors.red.shade50;
    case 'high':
      return Colors.orange.shade50;
    case 'medium':
      return Colors.blue.shade50;
    case 'normal':
      return Colors.green.shade50;
    default:
      return Colors.white;
  }
}

int getUrgencyPriority(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'urgent':
      return 4;
    case 'high':
      return 3;
    case 'medium':
      return 2;
    case 'normal':
      return 1;
    default:
      return 1;
  }
}

Color getBorderColor(Color bgColor) {
  if (bgColor == Colors.red.shade50) return Colors.red.shade200;
  if (bgColor == Colors.orange.shade50) return Colors.orange.shade200;
  if (bgColor == Colors.blue.shade50) return Colors.blue.shade200;
  if (bgColor == Colors.green.shade50) return Colors.green.shade200;
  return Colors.grey.shade200;
}

Color getComplexityColor(String complexity) {
  switch (complexity.toLowerCase()) {
    case 'high':
      return Colors.red;
    case 'medium':
      return Colors.orange;
    default:
      return Colors.green;
  }
}

void showDownloadDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required double progress,
  VoidCallback? onCancel,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => DownloadDialog(
      title: title,
      subtitle: subtitle,
      progress: progress,
      onCancel: onCancel,
    ),
  );
}

class DownloadDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final VoidCallback? onCancel;

  const DownloadDialog({
    required this.title,
    required this.subtitle,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arrow-down icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4285F4),
              ),
              child: const Icon(
                Icons.arrow_downward,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle (file name)
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4285F4),
              ),
            ),
            const SizedBox(height: 8),

            // Percentage text
            Text(
              '${(progress * 100).toInt()}% completed',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4285F4),
                  side: const BorderSide(color: Color(0xFF4285F4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onCancel ?? () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showLoadingDialog(BuildContext context, [String message = 'Loading...']) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.8, // 80% of screen width
            maxHeight: size.height * 0.3, // 30% of screen height
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.fade,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonText = 'OK',
  VoidCallback? onPressed,
}) {
  showDialog(
    context: context,
    builder: (ctx) => ErrorDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
    ),
  );
}

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const ErrorDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red X circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.error,
              ),
              child: const Icon(Icons.close, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // OK Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA4335),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onPressed != null) onPressed!();
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String primaryButtonText = 'Back',
  String? secondaryButtonText,
  VoidCallback? onPrimary,
  VoidCallback? onSecondary,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => SuccessDialog(
      title: title,
      message: message,
      primaryButtonText: primaryButtonText,
      secondaryButtonText: secondaryButtonText,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
    ),
  );
}

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const SuccessDialog({
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green check-circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              child: const Icon(Icons.check, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // Buttons row
            Row(
              children: [
                if (secondaryButtonText != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed:
                          onSecondary ?? () => Navigator.of(context).pop(),
                      child: Text(
                        secondaryButtonText!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                if (secondaryButtonText != null) const SizedBox(width: 12),

                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onPrimary != null) onPrimary!();
                    },
                    child: Text(
                      primaryButtonText,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showPendingDialog(
  BuildContext context, {
  required String title,
  required String message,
  String primaryButtonText = 'Back to Home',
  VoidCallback? onPrimary,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              "Payment Pending",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // OK Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onPrimary ?? () => Navigator.of(context).pop(),
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String affirmativeText = 'Yes',
  String negativeText = 'No',
  required VoidCallback onAffirmative,
  VoidCallback? onNegative,
}) {
  showDialog(
    context: context,
    builder: (ctx) => ConfirmDialog(
      title: title,
      message: message,
      affirmativeText: affirmativeText,
      negativeText: negativeText,
      onAffirmative: onAffirmative,
      onNegative: onNegative,
    ),
  );
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String affirmativeText;
  final String negativeText;
  final VoidCallback onAffirmative;
  final VoidCallback? onNegative;

  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.affirmativeText,
    required this.negativeText,
    required this.onAffirmative,
    this.onNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red cross-circle
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
              ),
              child: const Icon(Icons.warning, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAffirmative();
                    },
                    child: Text(
                      affirmativeText,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onNegative != null) {
                        onNegative!();
                      }
                    },
                    child: Text(
                      negativeText,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoPreviewList extends StatelessWidget {
  final List<File> images;
  final ValueSetter<int> onRemove;

  const PhotoPreviewList({
    super.key,
    required this.images,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(images.length, (index) {
          final file = images[index];
          if (!file.existsSync()) return const SizedBox.shrink();

          return SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      onRemove(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

Widget buildStatusBadge(String status) {
  final baseColor = getStatusColor(status);
  final backgroundColor = baseColor.withValues(alpha: 0.1);
  final foregroundColor = baseColor;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(5.0),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

Widget buildPriceRow(
  BuildContext context,
  String label,
  String amount, {
  bool isTotal = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: isTotal ? Colors.black : Colors.grey[600],
          fontSize: isTotal ? 15 : 12,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      Text(
        amount,
        style: TextStyle(
          color: isTotal ? Theme.of(context).primaryColor : Colors.black,
          fontSize: isTotal ? 18 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

Widget buildTimeRow(String label, String time) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      Text(time, style: const TextStyle(fontSize: 14)),
    ],
  );
}

// For add review and edit review
Widget buildHeaderCard(Map<String, dynamic> headerData) {
  try {
    final request = headerData['request'] as ServiceRequestModel;
    final service = headerData['service'] as ServiceModel?;
    final handyman = headerData['handymanUser'] as UserModel?;

    String formatDate(DateTime? date) {
      if (date == null) return 'Not scheduled';
      return DateFormat('MMMM dd, yyyy').format(date);
    }

    String formatTime(DateTime? date) {
      if (date == null) return 'Not set';
      return DateFormat('hh:mm a').format(date);
    }

    final serviceName = service?.serviceName ?? 'Unknown Service';
    final serviceIcon = ServiceHelper.getIconForService(serviceName);
    final serviceIconBg = ServiceHelper.getColorForService(serviceName);
    final handymanName = handyman?.userName ?? 'Unknown Handyman';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: serviceIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(serviceIcon, size: 25, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Text(
                serviceName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade300, height: 24),
          buildInfoRow('Location', request.reqAddress),
          const SizedBox(height: 12),
          buildInfoRow('Booking date', formatDate(request.scheduledDateTime)),
          const SizedBox(height: 12),
          buildInfoRow('Booking time', formatTime(request.scheduledDateTime)),
          const SizedBox(height: 12),
          buildInfoRow('Handyman name', handymanName),
        ],
      ),
    );
  } catch (e, stack) {
    rethrow;
  }
}

Widget buildInfoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          maxLines: 5,
        ),
      ),
    ],
  );
}

Widget buildStarRatingInput(RatingReviewController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Text(
        'How was your experience?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          bool noRating = controller.currentRating == 0;

          return IconButton(
            icon: Icon(
              controller.currentRating > index ? Icons.star : Icons.star_border,
              color: noRating ? Colors.black : Colors.amber,
              size: 40,
            ),
            onPressed: () {
              controller.setRating(index + 1.0);
            },
          );
        }),
      ),
    ],
  );
}

Widget buildReviewTextField(RatingReviewController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Review',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller.reviewController,
        maxLines: 8,
        style: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your review text here',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    ],
  );
}

// Employee side info card
class EmpInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<MapEntry<String, String>> details;
  final VoidCallback onViewDetails;
  final Color? backgroundColor;

  const EmpInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.details,
    required this.onViewDetails,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: backgroundColor ?? Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: backgroundColor != null
            ? BorderSide(color: getBorderColor(backgroundColor!), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // Flexible(
                //   fit: FlexFit.loose,
                //   child: ElevatedButton(
                //     onPressed: onViewDetails,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Theme.of(context).colorScheme.primary,
                //       foregroundColor: Colors.white,
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 16,
                //         vertical: 8,
                //       ),
                //       minimumSize: const Size(0, 36),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(6),
                //       ),
                //     ),
                //     child: const Text('View Details'),
                //   ),
                // ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.grey[500]),
            const SizedBox(height: 12),

            ...details.map((e) {
              final isStatusRow = e.key.toLowerCase().contains('status');
              final isUrgencyRow = e.key.toLowerCase().contains('urgency');
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: isStatusRow
                              ? getStatusColor(e.value)
                              : isUrgencyRow
                              ? getUrgencyColor(e.value)
                              : Colors.black87,
                          fontSize: 13,
                          fontWeight: (isStatusRow || isUrgencyRow)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class CancelRequestDialog extends StatefulWidget {
  final String reqID;
  final Future<void> Function(String reqID, String reason) onConfirmCancel;
  final VoidCallback? onSuccess;

  const CancelRequestDialog({
    required this.reqID,
    required this.onConfirmCancel,
    this.onSuccess,
  });

  @override
  State<CancelRequestDialog> createState() => CancelRequestDialogState();
}

class CancelRequestDialogState extends State<CancelRequestDialog> {
  late final TextEditingController reasonController;

  @override
  void initState() {
    super.initState();
    reasonController = TextEditingController();
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Stack(
        children: [
          const Center(
            child: Text(
              'Cancel Service Request',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.close, size: 22, color: Colors.black),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please provide a reason for cancelling this service request:',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Enter cancellation reason...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              counterText: '',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: reasonController,
          builder: (context, value, child) {
            final bool isReasonEntered = value.text.trim().isNotEmpty;

            return ElevatedButton(
              onPressed: isReasonEntered
                  ? () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a cancellation reason'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Close reason dialog
                      if (!context.mounted) return;
                      final parentContext = Navigator.of(context).context;
                      Navigator.of(context).pop();

                      await Future.delayed(const Duration(milliseconds: 100));

                      // Show confirm dialog
                      if (!parentContext.mounted) return;
                      showDialog(
                        context: parentContext,
                        barrierDismissible: false,
                        builder: (confirmDialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          content: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.amber,
                                  ),
                                  child: const Icon(
                                    Icons.warning,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Confirm Cancellation',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Are you sure you want to cancel this service request? This action cannot be undone.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: () async {
                                          // Close confirm dialog first
                                          Navigator.of(
                                            confirmDialogContext,
                                          ).pop();

                                          // Show loading dialog
                                          if (!parentContext.mounted) return;
                                          showDialog(
                                            context: parentContext,
                                            barrierDismissible: false,
                                            builder: (loadingContext) => WillPopScope(
                                              onWillPop: () async => false,
                                              child: const Center(
                                                child: Card(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(20),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        CircularProgressIndicator(),
                                                        SizedBox(height: 16),
                                                        Text(
                                                          'Cancelling service request...',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );

                                          try {
                                            // Perform the cancellation
                                            await widget.onConfirmCancel(
                                              widget.reqID,
                                              reason,
                                            );

                                            // Close loading dialog
                                            if (parentContext.mounted) {
                                              Navigator.of(parentContext).pop();
                                            }

                                            // Show success dialog
                                            if (!parentContext.mounted) return;
                                            await showDialog(
                                              context: parentContext,
                                              builder: (successContext) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                                content: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 20,
                                                      ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 80,
                                                        height: 80,
                                                        decoration:
                                                            const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          size: 48,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      const Text(
                                                        'Request Cancelled',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      const Text(
                                                        'Your service request has been cancelled successfully',
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      const SizedBox(
                                                        height: 32,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: FilledButton(
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 14,
                                                                ),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                              successContext,
                                                            ).pop();
                                                            widget.onSuccess
                                                                ?.call();
                                                          },
                                                          child: const Text(
                                                            'OK',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            // Close loading dialog
                                            if (parentContext.mounted) {
                                              Navigator.of(parentContext).pop();
                                            }

                                            // Show error dialog
                                            if (!parentContext.mounted) return;
                                            showDialog(
                                              context: parentContext,
                                              builder: (errorContext) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                                content: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 20,
                                                      ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 80,
                                                        height: 80,
                                                        decoration:
                                                            const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Colors.red,
                                                            ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          size: 48,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      const Text(
                                                        'Cancellation Failed',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        'Failed to cancel request: $e',
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      const SizedBox(
                                                        height: 32,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: FilledButton(
                                                          style: FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 14,
                                                                ),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                              errorContext,
                                                            ).pop();
                                                          },
                                                          child: const Text(
                                                            'OK',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          'Confirm',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(
                                            confirmDialogContext,
                                          ).pop();
                                        },
                                        child: const Text(
                                          'Back',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
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
                      );
                    }
                  : null, // Button is disabled if reason is empty
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Next'),
            );
          },
        ),
      ],
    );
  }
}

void showCancelRequestDialog(
  BuildContext context, {
  required String reqID,
  required Future<void> Function(String reqID, String reason) onConfirmCancel,
  VoidCallback? onSuccess,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return CancelRequestDialog(
        reqID: reqID,
        onConfirmCancel: onConfirmCancel,
        onSuccess: onSuccess,
      );
    },
  );
}

IconData getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.schedule;
    case 'confirmed':
      return Icons.check_circle_outline;
    case 'departed':
      return Icons.directions_walk;
    case 'completed':
      return Icons.check_circle;
    case 'cancelled':
      return Icons.cancel;
    default:
      return Icons.info_outline;
  }
}

IconData getReportIcon(String type) {
  switch (type.toLowerCase()) {
    case 'handyman performance':
      return Icons.trending_up;
    case 'financial':
      return Icons.attach_money;
    case 'service request':
      return Icons.build;
    default:
      return Icons.description;
  }
}

// Allow rescheduling if is 2+ days before the scheduled date
Future<void> showRescheduleDialog(
  BuildContext context, {
  required ServiceRequestController controller,
  required String reqID,
  required VoidCallback onSuccess,
}) async {
  try {
    await controller.rescheduleRequest(reqID);
    if (!context.mounted) return;

    // Show the datetime picker dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) =>
          RescheduleDialog(controller: controller, onSuccess: onSuccess),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
    );
  }
}

class RescheduleDialog extends StatefulWidget {
  final ServiceRequestController controller;
  final VoidCallback onSuccess;

  const RescheduleDialog({required this.controller, required this.onSuccess});

  @override
  State<RescheduleDialog> createState() => RescheduleDialogState();
}

class RescheduleDialogState extends State<RescheduleDialog> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Stack(
        children: [
          const Center(
            child: Text(
              'Reschedule Service Request',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                widget.controller.clearRescheduleData();
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.close, size: 22, color: Colors.black),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select a new date and time for your service request.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Date Selection
            OutlinedButton.icon(
              onPressed: isLoading ? null : selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate == null
                    ? 'Select Date'
                    : DateFormat('MMMM dd, yyyy').format(selectedDate!),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            // Time Selection
            OutlinedButton.icon(
              onPressed: isLoading || selectedDate == null ? null : selectTime,
              icon: const Icon(Icons.access_time),
              label: Text(
                selectedTime == null
                    ? 'Select Time'
                    : selectedTime!.format(context),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 16),

            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The new date must be at least 2 days from today. We will check availability and may assign a different handyman if needed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: isLoading || selectedDate == null || selectedTime == null
              ? null
              : confirmReschedule,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }

  Future<void> selectDate() async {
    final now = DateTime.now();
    // Minimum date is 2 days from today
    final minDate = now.add(const Duration(days: 2));
    // Maximum date is 3 months from today
    final maxDate = now.add(const Duration(days: 90));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        // Reset time when date changes
        selectedTime = null;
      });
    }
  }

  Future<void> selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> confirmReschedule() async {
    if (selectedDate == null || selectedTime == null) return;

    // Combine date and time
    final newScheduledDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // Validate that the date/time is at least 2 days from now
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final scheduleDay = DateUtils.dateOnly(newScheduledDateTime);
    final daysUntilScheduled = scheduleDay.difference(today).inDays;

    if (daysUntilScheduled < 2) {
      showErrorDialog(
        context,
        title: 'Invalid Date',
        message: 'The new date must be at least 2 days from today.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await widget.controller.confirmRescheduleWithConflictCheck(
        newScheduledDateTime,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      showSuccessDialog(
        context,
        title: 'Reschedule Successful',
        message:
            'Service request rescheduled to ${DateFormat('MMM dd, yyyy hh:mm a').format(newScheduledDateTime)}',
        primaryButtonText: 'OK',
        onPrimary: widget.onSuccess,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showErrorDialog(
        context,
        title: 'Reschedule Failed',
        message: e.toString(),
      );
    }
  }
}
