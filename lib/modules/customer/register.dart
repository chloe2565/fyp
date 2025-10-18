import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../helper.dart';
import '../../login.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: const RegisterList(),
    );
  }
}

enum Gender { male, female }

class RegisterList extends StatefulWidget {
  const RegisterList({super.key});

  @override
  State<RegisterList> createState() => _RegisterListState();
}

class _RegisterListState extends State<RegisterList> {
  bool acceptTerms = false;

  final UserController _controller = UserController(
    showErrorSnackBar: (msg) => debugPrint(msg),
  );

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
          child: Form (
            key: _controller.formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Getting Started" title
                  Text(
                    'Getting Started',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    "Let's set up your account.",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 25),

                  // Name input field
                  TextFormField(
                    controller: _controller.nameController,
                    decoration: InputDecoration(
                      labelText: "Enter your name",
                      prefixIcon: Icon(
                        Icons.person_outlined,
                      ),
                      errorMaxLines: 3,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validator.validateName,
                  ),
                  const SizedBox(height: 20),

                  // Email input field
                  TextFormField(
                    controller: _controller.emailController,
                    decoration: InputDecoration(
                      labelText: "Enter your email",
                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                      errorMaxLines: 3,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validator.validateEmail,
                  ),
                  const SizedBox(height: 20),

                  // Gender radio button field
                  Row(
                    children: [
                      Text(
                        "Gender: ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Radio(
                        value: Gender.male,
                        groupValue: _controller.gender,
                        onChanged: (val) =>
                            setState(() => _controller.gender = val),
                      ),
                      Text("Male"),
                      Radio(
                        value: Gender.female,
                        groupValue: _controller.gender,
                        onChanged: (val) =>
                            setState(() => _controller.gender = val),
                      ),
                      Text("Female"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Phone input field
                  TextFormField(
                    controller: _controller.phoneController,
                    decoration: InputDecoration(
                      labelText: "Enter your phone",
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                      ),
                      errorMaxLines: 3,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validator.validateContact,
                  ),
                  const SizedBox(height: 20),

                  // Password input field
                  TextFormField(
                    controller: _controller.newPasswordController,
                    obscureText: _controller.obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: "Enter your password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _controller.obscureNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.toggleNewPasswordVisibility();
                          });
                        },
                      ),
                      errorMaxLines: 3,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validator.validatePassword,
                  ),
                  const SizedBox(height: 20),

                  // Confirm password input field
                  TextFormField(
                    controller: _controller.confirmPasswordController,
                    obscureText: _controller.obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Confirm your password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _controller.obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.toggleConfirmPasswordVisibility();
                          });
                        },
                      ),
                      errorMaxLines: 3,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (val) => Validator.validateConfirmPassword(val, _controller.confirmPasswordController.text),
                  ),
                  const SizedBox(height: 16),

                  // Terms condition
                  Row(
                    children: [
                      Checkbox(
                        value: acceptTerms,
                        onChanged: (bool? value) {
                          setState(() {
                            acceptTerms = value ?? false;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to Terms and Conditions page or show a dialog
                          },
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'By creating an account, you agree to our ',
                                ),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (!acceptTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("You must accept Terms & Conditions")),
                          );
                          return;
                        }
                        _controller.register(context, setState);
                      },
                      child: const Text("Register"),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // "Don't have an account? Sign Up" text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Already have an account?",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()));
                        },
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ),

        // Fullscreen loading overlay
        if (_controller.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ]
    );
  }
}