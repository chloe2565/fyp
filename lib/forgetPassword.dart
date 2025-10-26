import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/helper.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const ForgetPasswordList(),
    );
  }
}

class ForgetPasswordList extends StatefulWidget {
  const ForgetPasswordList({super.key});

  @override
  State<ForgetPasswordList> createState() => ForgetPasswordListState();
}

class ForgetPasswordListState extends State<ForgetPasswordList> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

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
                    controller: emailController,
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
                onPressed: isLoading ? null : resetPassword,
                child: isLoading
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

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showErrorDialog(
        context,
        title: 'Error',
        message: "Please enter your email.",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showSuccessDialog(
        context,
        title: 'Email Successfully Sent',
        message: 'A password reset link has been sent to your email.',
        primaryButtonText: 'Login',
        onPrimary: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back from ForgetPassword screen
        },
      );
    } on FirebaseAuthException catch (e) {
      showErrorDialog(
        context,
        title: 'Error',
        message: e.message ?? "Something went wrong.",
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
