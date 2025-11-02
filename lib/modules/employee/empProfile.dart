import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../model/databaseModel.dart';
import '../../shared/helper.dart';
import '../../login.dart';
import 'empEditProfile.dart';

class EmpProfileScreen extends StatefulWidget {
  const EmpProfileScreen({super.key});

  @override
  State<EmpProfileScreen> createState() => EmpProfileScreenState();
}

class EmpProfileScreenState extends State<EmpProfileScreen> {
  UserModel? userModel;
  bool isLoading = true;
  String? errorMessage;

  late UserController userController;

  @override
  void initState() {
    super.initState();
    userController = UserController(
      showErrorSnackBar: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );

    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = await userController.getCurrentUser();
      setState(() {
        userModel = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load profile: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : userModel == null
          ? const Center(child: Text('No user data found'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Profile Picture
                    Container(
                      height: 120,
                      width: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/profile.jpg'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Profile Details
                    ProfileInfoTile(label: 'Name', value: userModel!.userName),
                    const SizedBox(height: 24),
                    ProfileInfoTile(
                      label: 'Email Address',
                      value: userModel!.userEmail,
                    ),
                    const SizedBox(height: 24),
                    ProfileInfoTile(
                      label: 'Gender',
                      value: userModel!.userGender == 'M' ? 'Male' : 'Female',
                    ),
                    const SizedBox(height: 24),
                    ProfileInfoTile(
                      label: 'Contact Number',
                      value: Formatter.formatPhoneNumber(
                        userModel!.userContact,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: userModel != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EmpEditProfileScreen(
                                          initialName: userModel!.userName,
                                          initialEmail: userModel!.userEmail,
                                          initialGender:
                                              userModel!.userGender == 'M'
                                              ? Gender.male
                                              : Gender.female,
                                          initialPhoneNumber:
                                              userModel!.userContact,
                                          userID: userModel!.userID,
                                        ),
                                      ),
                                    ).then((_) => fetchUserData());
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: userModel != null
                                ? () {
                                    userController.emailController.text =
                                        userModel!.userEmail;
                                    showDeleteAccountDialog(
                                      context: context,
                                      emailController:
                                          userController.emailController,
                                      onDelete: () async {
                                        await userController.deleteAccount(
                                          email: userController
                                              .emailController
                                              .text
                                              .trim(),
                                          setState: setState,
                                        );
                                        if (userController.isLoading == false &&
                                            context.mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen(),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF3D3D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: const Text(
                              'Delete Account',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: userModel != null
                          ? () {
                              showChangePasswordDialog(
                                context: context,
                                currentPasswordController:
                                    userController.currentPasswordController,
                                newPasswordController:
                                    userController.newPasswordController,
                                confirmNewPasswordController:
                                    userController.confirmPasswordController,
                                onSubmit: () async {
                                  await userController.changePassword(
                                    currentPassword: userController
                                        .currentPasswordController
                                        .text
                                        .trim(),
                                    newPassword: userController
                                        .newPasswordController
                                        .text
                                        .trim(),
                                    confirmNewPassword: userController
                                        .confirmPasswordController
                                        .text
                                        .trim(),
                                    setState: setState,
                                  );
                                  if (userController.isLoading == false &&
                                      context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFD722E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text(
                        'Change Password',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  const ProfileInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
