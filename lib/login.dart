import 'package:flutter/material.dart';
import 'shared/helper.dart';
import 'forgetPassword.dart';
import 'modules/customer/register.dart';
import 'controller/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  late final UserController controller;

  @override
  void initState() {
    super.initState();
    controller = UserController(
      showErrorSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: LoginList(
            controller: controller,
            parentSetState: setState,
          ),
        ),
        if (controller.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class LoginList extends StatefulWidget {
  final UserController controller;
  final Function(VoidCallback) parentSetState;

  const LoginList({
    super.key,
    required this.controller,
    required this.parentSetState,
  });

  @override
  State<LoginList> createState() => LoginListState();
}

class LoginListState extends State<LoginList> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // "Welcome Back!" title
            Text(
              'Welcome Back!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Your Smart Home, Your Rules.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 25),

            // Form
            Form(
              key: widget.controller.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  // Email input field
                  TextFormField(
                    controller: widget.controller.emailController,
                    decoration: InputDecoration(
                      labelText: 'Enter your email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                      errorMaxLines: 3,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validator.validateEmail,
                  ),
                  const SizedBox(height: 20),

                  // Password input field
                  TextFormField(
                    controller: widget.controller.currentPasswordController,
                    obscureText: widget.controller.obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Enter your password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          widget.controller.obscureCurrentPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            widget.controller.toggleCurrentPasswordVisibility();
                          });
                        },
                      ),
                      errorMaxLines: 3,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validator.validatePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // "Forgot Password?"
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgetPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // "Login" button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.controller.isLoading
                    ? null
                    : () => widget.controller.login(
                          context,
                          widget.parentSetState,
                        ),
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 15),

            // "OR" divider
            Row(
              children: <Widget>[
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.surfaceDim,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.surfaceDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // "Continue with Google" button
            OutlinedButton(
              onPressed: () => widget.controller.signInWithGoogle(
                context,
                widget.parentSetState,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/google_icon.png',
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // "Don't have an account? Sign Up" text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Don't have an account?",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(
                            context,
                          ).colorScheme.primary,
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