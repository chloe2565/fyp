import 'package:flutter/material.dart';
import 'helper.dart';
import 'navigatorBase.dart';
import 'forget_password.dart';
import 'modules/customer/register.dart';
import 'modules/customer/homepage.dart';
import 'model/user.dart'; // Ensure this path is correct
import 'service/auth_service.dart'; // Ensure this path is correct
import 'controller/user_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const LoginList(),
    );
  }
}

class LoginList extends StatefulWidget {
  const LoginList({super.key});

  @override
  State<LoginList> createState() => _LoginListState();
}

class _LoginListState extends State<LoginList> {
  late final UserController _controller; // Initialize with late

  @override
  void initState() {
    super.initState();
    _controller = UserController(
      // Pass a function to display snackbar from the state
      showErrorSnackBar: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
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
                  key: _controller.formKey,
                  // Enable real-time validation as the user types
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      // Email input field
                      TextFormField(
                        controller: _controller.emailController,
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
                        controller: _controller.currentPasswordController,
                        obscureText: _controller.obscureCurrentPassword,
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
                              _controller.obscureCurrentPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.toggleCurrentPasswordVisibility();
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
                    onPressed: _controller.isLoading
                        ? null // disable the button when loading
                        : () => _controller.login(context, setState),
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
                  onPressed: () =>
                      _controller.signInWithGoogle(context, setState),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/google_icon.png',
                        // Ensure this path is correct
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
        ),

        // Fullscreen Loading overlay
        if (_controller.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54, // semi-transparent background
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
