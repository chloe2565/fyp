import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: const ForgetPasswordList(),
    );
  }
}

class ForgetPasswordList extends StatefulWidget {
  const ForgetPasswordList({super.key});

  @override
  State<ForgetPasswordList> createState() => _ForgetPasswordListState();
}

class _ForgetPasswordListState extends State<ForgetPasswordList> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // "Getting Started" title
            Text(
              'Forget Password',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              "Enter your email address to reset password",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 25),

            // Email input field
            Focus(
              child: Builder(
                builder: (BuildContext context) {
                  final bool hasFocus = Focus.of(context).hasFocus;
                  return TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Enter your email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: hasFocus
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Reset password button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reset Password'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog("Please enter your email.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Something went wrong.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Use min size for the content
            children: [
              const SizedBox(height: 20),
              // The green checkmark circle
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1CB870),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 70,
                ),
              ),
              const SizedBox(height: 24),
              // The title text
              const Text(
                "Email Successfully Sent",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF056137), // Dark green color
                ),
              ),
              const SizedBox(height: 10),
              // The descriptive message
              const Text(
                "A password reset link has been sent to your email.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF056137), // Lighter green color
                ),
              ),
              const SizedBox(height: 20),
              // The Login button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // 1. Close the dialog
                    Navigator.of(context).pop();
                    // 2. Go back from the Forget Password screen
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

}