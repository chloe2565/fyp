import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/modules/customer/edit_profile.dart';
import '../../controller/user_controller.dart';
import '../../login.dart';
import '../../model/user.dart';
import '../../service/firestore_service.dart';
import '../../helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  late UserController _userController;

  @override
  void initState() {
    super.initState();
    _userController = UserController(
      showErrorSnackBar: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authID = FirebaseAuth.instance.currentUser?.uid;
      if (authID == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final firestoreService = FirestoreService();
      final user = await firestoreService.getUserByAuthID(authID);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _userController.dispose();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _user == null
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
                    _ProfileInfoTile(label: 'Name', value: _user!.userName),
                    const SizedBox(height: 24),
                    _ProfileInfoTile(
                      label: 'Email Address',
                      value: _user!.userEmail,
                    ),
                    const SizedBox(height: 24),
                    _ProfileInfoTile(
                      label: 'Gender',
                      value: _user!.userGender == 'M' ? 'Male' : 'Female',
                    ),
                    const SizedBox(height: 24),
                    _ProfileInfoTile(
                      label: 'Contact Number',
                      value: Formatter.formatPhoneNumber(_user!.userContact),
                    ),
                    const SizedBox(height: 50),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _user != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(
                                          initialName: _user!.userName,
                                          initialEmail: _user!.userEmail,
                                          initialGender:
                                              _user!.userGender == 'M'
                                              ? Gender.male
                                              : Gender.female,
                                          initialPhoneNumber:
                                              _user!.userContact,
                                          userID: _user!.userID,
                                        ),
                                      ),
                                    ).then((_) => _fetchUserData());
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
                              'Edit Profile',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _user != null
                                ? () {
                                    _userController.emailController.text =
                                        _user!.userEmail;
                                    showDeleteAccountDialog(
                                      context: context,
                                      emailController:
                                          _userController.emailController,
                                      onDelete: () async {
                                        await _userController.deleteAccount(
                                          email: _userController
                                              .emailController
                                              .text
                                              .trim(),
                                          setState: setState,
                                        );
                                        if (_userController.isLoading ==
                                                false &&
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
                      onPressed: _user != null
                          ? () {
                              showChangePasswordDialog(
                                context: context,
                                currentPasswordController:
                                    _userController.currentPasswordController,
                                newPasswordController:
                                    _userController.newPasswordController,
                                confirmNewPasswordController:
                                    _userController.confirmPasswordController,
                                onSubmit: () async {
                                  await _userController.changePassword(
                                    currentPassword: _userController
                                        .currentPasswordController
                                        .text
                                        .trim(),
                                    newPassword: _userController
                                        .newPasswordController
                                        .text
                                        .trim(),
                                    confirmNewPassword: _userController
                                        .confirmPasswordController
                                        .text
                                        .trim(),
                                    setState: setState,
                                  );
                                  if (_userController.isLoading == false &&
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

class _ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
