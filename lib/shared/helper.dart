import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildPasswordField(
                        context: context,
                        label: 'Current Password',
                        hint: 'Enter current password',
                        controller: currentPasswordController,
                        isVisible: isCurrentPasswordVisible,
                        obscureText: true,
                        validator: (value) => value!.isEmpty
                            ? 'Current Password is required'
                            : null,
                        onVisibilityChanged: () {
                          setDialogState(() {
                            isCurrentPasswordVisible =
                                !isCurrentPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      buildPasswordField(
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
                      buildPasswordField(
                        context: context,
                        label: 'Confirm New Password',
                        hint: 'Confirm new password',
                        controller: confirmNewPasswordController,
                        isVisible: isConfirmNewPasswordVisible,
                        obscureText: true,
                        validator: (value) => Validator.validateConfirmPassword(
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
                          onPressed: (formKey.currentState?.validate() ?? false)
                              ? onSubmit
                              : null,
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
  final String avatarAssetPath = reviewData.avatarPath.isNotEmpty
      ? 'assets/images/${reviewData.avatarPath}'
      : 'assets/images/profile.jpg';

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
          backgroundImage: AssetImage(avatarAssetPath),
          backgroundColor: Colors.grey.shade200,
          onBackgroundImageError: (exception, stackTrace) {
            print('Error loading avatar: $avatarAssetPath');
          },
          child: reviewData.avatarPath.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
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
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: IconButton(
          icon: const Icon(Icons.tune),
          color: Theme.of(context).colorScheme.primary,
          onPressed: onFilterPressed,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
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
              width: MediaQuery.of(context).size.width / (tabs.length * 2),
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
      shadowColor: Colors.black.withOpacity(0.1),
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
                    ).colorScheme.primary.withOpacity(0.1),
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
    final bool isStatusRow =
        lowerTitle == 'status' || lowerTitle == 'payment status';
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
            child: Text(
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

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.amber;
    case 'confirmed':
      return Color(0xFFFD722E);
    case 'departed':
      return Colors.blue;
    case 'completed':
    case 'paid':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
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
    builder: (ctx) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    ),
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
                onPressed: onPressed ?? () => Navigator.of(context).pop(),
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
  String primaryButtonText = 'Back to Home',
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
                    onPressed: onPrimary ?? () => Navigator.of(context).pop(),
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
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 48, color: Colors.white),
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
                color: Color(0xFFEA4335),
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

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
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
                    onPressed: onNegative ?? () => Navigator.of(context).pop(),
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
      height: 100,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    images[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}













