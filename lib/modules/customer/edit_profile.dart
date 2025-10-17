// edit_profile.dart (modified)
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
  bool _isEmailVerifying = false;
  bool _isEmailVerified = true;
  bool _showVerificationDialog = false;
  String? _originalEmail;
  String? _originalContact;
  String? _emailError;
  String? _phoneError;

  late UserController _userController;
  final FirestoreService _firestoreService = FirestoreService();

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
    _originalEmail = widget.initialEmail.toLowerCase();
    _originalContact = widget.initialPhoneNumber;
    _isEmailVerified = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _userController.dispose();
    super.dispose();
  }

  // Send verification email
  Future<void> _sendVerificationEmail() async {
    final email = _emailController.text.trim();
    if (email.toLowerCase() == _originalEmail) return;

    setState(() => _isEmailVerifying = true);

    try {
      await _userController.sendEmailVerification(email);
      setState(() => _showVerificationDialog = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEmailVerifying = false);
    }
  }

  // Check if verified
  Future<void> _checkVerified() async {
    final email = _emailController.text.trim().toLowerCase();
    setState(() => _isEmailVerifying = true);

    try {
      final isValid = await _userController.isEmailVerifiedWithNew(email);

      if (isValid && mounted) {
        setState(() {
          _isEmailVerified = true;
          _showVerificationDialog = false;
          _emailError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not yet verified. Please click the link in your email.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isEmailVerifying = false);
    }
  }

  // Resend code
  Future<void> _resendCode() async {
    await _sendVerificationEmail();
  }

  Future<void> _submitProfile() async {
    // Email verification check
    if (_emailController.text.trim().toLowerCase() != _originalEmail &&
        !_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Click the tick to verify your new email first'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _userController.updateProfile(
          userID: widget.userID,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          gender: _genderItem == Gender.male ? 'M' : 'F',
          contact: _phoneController.text.trim(),
          setState: setState,
          context: context,
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
        if (mounted) setState(() => _isLoading = false);
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
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                    onTap: () => debugPrint(
                                      'Edit profile picture tapped!',
                                    ),
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

                          // Name Field
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
                            validator: Validator.validateName,
                          ),
                          const SizedBox(height: 24),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey,
                              ),
                              suffixIcon:
                                  _emailController.text.trim().toLowerCase() !=
                                      _originalEmail
                                  ? IconButton(
                                      icon: Icon(
                                        _isEmailVerified
                                            ? Icons.verified
                                            : Icons.verified_outlined,
                                        color: _isEmailVerified
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      onPressed: _isEmailVerifying
                                          ? null
                                          : _sendVerificationEmail,
                                    )
                                  : const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                              errorMaxLines: 3,
                              suffixStyle: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: Theme.of(context).textTheme.bodySmall,
                            onChanged: (value) async {
                              setState(() {
                                _isEmailVerified = false;
                                _emailError = null;
                              });
                              if (Validator.validateEmail(value) == null) {
                                String email = value.trim().toLowerCase();
                                if (email != _originalEmail) {
                                  bool taken = await _firestoreService
                                      .isEmailTaken(email, widget.userID);
                                  if (taken) {
                                    setState(() {
                                      _emailError =
                                          'This email is already registered';
                                    });
                                  } else {
                                    setState(() {
                                      _emailError =
                                          'Click the tick to verify email to continue';
                                    });
                                  }
                                }
                              }
                            },
                            validator: Validator.validateEmail,
                          ),
                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _emailError!,
                                style: TextStyle(
                                  color: _emailError!.contains('verify')
                                      ? Colors.orange
                                      : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Gender
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
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<Gender>(
                                      value: Gender.male,
                                      groupValue: _genderItem,
                                      onChanged: (value) =>
                                          setState(() => _genderItem = value),
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
                                      onChanged: (value) =>
                                          setState(() => _genderItem = value),
                                    ),
                                    const Text('Female'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Phone Field
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
                            onChanged: (value) async {
                              setState(() {
                                _phoneError = null;
                              });
                              if (Validator.validateContact(value) == null) {
                                String contact = value.trim();
                                if (contact != _originalContact) {
                                  bool taken = await _firestoreService
                                      .isPhoneTaken(contact, widget.userID);
                                  if (taken) {
                                    setState(() {
                                      _phoneError =
                                          'This phone number is already registered';
                                    });
                                  }
                                }
                              }
                            },
                            validator: (value) {
                              final error = Validator.validateContact(value);
                              if (error != null) return error;
                              if (_phoneError != null) return _phoneError;
                              return null;
                            },
                          ),
                          if (_phoneError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _phoneError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 50),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : (_emailController.text
                                                    .trim()
                                                    .toLowerCase() ==
                                                _originalEmail ||
                                            _isEmailVerified)
                                      ? _submitProfile
                                      : null,
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

                // Verification Dialog
                if (_showVerificationDialog)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(child: _buildVerificationDialog()),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildVerificationDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 320, 
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Email Verified!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_emailController.text.trim()} is valid and ready!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEmailVerified = true;
                  _showVerificationDialog = false;
                  _emailError = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFD722E),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
