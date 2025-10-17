import 'package:flutter/material.dart';
import '../../controller/user_controller.dart';
import '../../service/firestore_service.dart';
import '../../model/user.dart';
import '../../helper.dart';

enum Gender { male, female }

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final Gender initialGender;
  final String initialPhoneNumber;
  final String userID;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialGender,
    required this.initialPhoneNumber,
    required this.userID,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  Gender? _genderItem;
  bool _isLoading = false;

  late UserController _userController;

  @override
  void initState() {
    super.initState();
    _userController = UserController(
      showErrorSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );

    String initialPhone = widget.initialPhoneNumber;
    String localNumber;
    if (initialPhone.startsWith('+60')) {
      localNumber = '0${initialPhone.substring(3)}';
    } else {
      localNumber = initialPhone;
    }

    _nameController.text = widget.initialName;
    _emailController.text = widget.initialEmail;
    _phoneController.text = localNumber;
    _genderItem = widget.initialGender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userController.updateProfile(
          userID: widget.userID,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          gender: _genderItem == Gender.male ? 'M' : 'F',
          contact: _phoneController.text.trim(),
          setState: setState,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode
                      .onUserInteraction, // REAL-TIME VALIDATION
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
                                onTap: () {
                                  debugPrint('Edit profile picture tapped!');
                                },
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

                      // Name Field - LIKE LOGIN
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey,
                          ),
                          errorMaxLines: 3,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: Validator.validateName,
                      ),
                      const SizedBox(height: 24),

                      // Email Field - LIKE LOGIN
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          errorMaxLines: 3,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: Theme.of(context).textTheme.bodySmall,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: Validator.validateEmail,
                      ),
                      const SizedBox(height: 24),

                      // Gender (unchanged)
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
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: [
                                Radio<Gender>(
                                  value: Gender.male,
                                  groupValue: _genderItem,
                                  onChanged: (Gender? value) {
                                    setState(() {
                                      _genderItem = value;
                                    });
                                  },
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
                                  groupValue: _genderItem,
                                  onChanged: (Gender? value) {
                                    setState(() {
                                      _genderItem = value;
                                    });
                                  },
                                ),
                                const Text('Female'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Phone Field - LIKE LOGIN
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: Colors.grey,
                          ),
                          errorMaxLines: 3,
                        ),
                        keyboardType: TextInputType.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: Validator.validateContact,
                      ),
                      const SizedBox(height: 50),

                      // Updated Submit Button - DISABLE IF INVALID
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _formKey.currentState!.validate()
                                  ? _submitProfile
                                  : null, // DISABLE IF INVALID
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFD722E),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
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
