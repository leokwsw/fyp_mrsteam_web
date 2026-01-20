import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() {
    // TODO: Implement login logic
    print('User ID: ${_userIdController.text}');
    print('Password: ${_passwordController.text}');

    // Navigate to dashboard after successful login
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Logo
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Icon(Icons.school, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'TutorTrack',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 450),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 60.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Welcome Text
                        Text(
                          'Welcome to TutorTrack',
                          style: AppTextStyles.heading,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // User ID Field
                        CustomTextField(
                          label: 'User ID',
                          placeholder: 'Enter your User ID',
                          controller: _userIdController,
                        ),
                        const SizedBox(height: 24),

                        // Password Field
                        CustomTextField(
                          label: 'Password',
                          placeholder: 'Enter your Password',
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        CustomButton(text: 'Login', onPressed: _handleLogin),
                        const SizedBox(height: 16),

                        // Forgot Password Link
                        TextButton(
                          onPressed: () {
                            context.push('/reset-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.link,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
