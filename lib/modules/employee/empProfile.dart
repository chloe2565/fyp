import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../controller/employee.dart';
import '../../shared/helper.dart';
import 'empEditProfile.dart';

class EmpProfileScreen extends StatefulWidget {
  const EmpProfileScreen({super.key});

  @override
  State<EmpProfileScreen> createState() => EmpProfileScreenState();
}

class EmpProfileScreenState extends State<EmpProfileScreen> {
  late final EmployeeController controller;
  late final UserController userCtrl;

  @override
  void initState() {
    super.initState();
    controller = EmployeeController()..loadProfile();
    userCtrl = UserController(
      showErrorSnackBar: (msg) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg))),
    );
  }

  @override
  void dispose() {
    userCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null) {
            return Center(child: Text(controller.error!));
          }

          final user = controller.user!;
          final emp = controller.employee!;
          final isHandyman = emp.empType == 'handyman';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                Center(
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                ),
                const SizedBox(height: 30),

                // Employee ID
                infoRow('Employee ID', emp.empID),
                const SizedBox(height: 24),

                // Employee Type
                infoRow(
                  'Employee Type',
                  isHandyman ? 'Handyman' : 'Service Provider (Admin)',
                ),
                const SizedBox(height: 24),

                // Employee Name
                infoRow('Employee Name', user.userName),
                const SizedBox(height: 24),

                // Employee Gender
                infoRow('Gender', user.userGender == 'M' ? 'Male' : 'Female'),
                const SizedBox(height: 24),

                // Employee Contact Number
                infoRow(
                  'Contact Number',
                  Formatter.formatPhoneNumber(user.userContact),
                  showFlag: true,
                ),
                const SizedBox(height: 24),

                // Employee Email
                infoRow('Email Address', user.userEmail),
                const SizedBox(height: 24),

                // Employee Service Assigned
                if (isHandyman) ...[
                  infoRow(
                    'Services Assigned',
                    controller.handymanServiceNames.isEmpty
                        ? 'No services assigned'
                        : controller.handymanServiceNames.join(', '),
                  ),
                  const SizedBox(height: 24),
                ],

                // Status
                infoRow(
                  'Status',
                  capitalizeFirst(emp.empStatus),
                  valueColor: getStatusColor(emp.empStatus),
                ),
                const SizedBox(height: 50),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showChangePasswordDialog(
                            context: context,
                            currentPasswordController:
                                userCtrl.currentPasswordController,
                            newPasswordController:
                                userCtrl.newPasswordController,
                            confirmNewPasswordController:
                                userCtrl.confirmPasswordController,
                            onSubmit: () async {
                              final error = await userCtrl.changePassword(
                                context: context,
                                currentPassword: userCtrl
                                    .currentPasswordController
                                    .text
                                    .trim(),
                                newPassword: userCtrl.newPasswordController.text
                                    .trim(),
                                confirmNewPassword: userCtrl
                                    .confirmPasswordController
                                    .text
                                    .trim(),
                                setState: setState,
                              );
                              return error;
                            },
                          );
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Change Password',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmpEditProfileScreen(
                              initialName: user.userName,
                              initialEmail: user.userEmail,
                              initialGender: user.userGender == 'M'
                                  ? Gender.male
                                  : Gender.female,
                              initialPhoneNumber: user.userContact,
                              userID: user.userID,
                              empID: emp.empID,
                              empType: emp.empType,
                              empStatus: emp.empStatus,
                              serviceAssigned: controller.handymanServiceNames,
                            ),
                          ),
                        ).then((_) => controller.loadProfile()),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget infoRow(
    String label,
    String value, {
    bool showFlag = false,
    Color? valueColor,
  }) {
    final TextStyle valueStyle = valueColor != null
        ? TextStyle(fontSize: 16, color: valueColor)
        : Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ) ??
              TextStyle(fontSize: 16, color: Colors.grey.shade600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 5),
          if (showFlag)
            Row(
              children: [
                const Text('🇲🇾', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: valueStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
