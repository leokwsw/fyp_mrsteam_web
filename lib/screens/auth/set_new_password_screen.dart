import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({Key? key}) : super(key: key);

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _handleSetPassword() {
    // TODO: Implement password validation and update logic
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    
    print('New Password: ${_newPasswordController.text}');
    
    // Navigate back to login after successful password reset
    context.go('/');
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
                        // Title
                        Text(
                          'Set New Password',
                          style: AppTextStyles.heading,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          'Please enter your new password',
                          style: AppTextStyles.link.copyWith(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // New Password Field
                        CustomTextField(
                          label: 'New Password',
                          placeholder: 'Enter new password',
                          isPassword: true,
                          controller: _newPasswordController,
                        ),
                        const SizedBox(height: 24),

                        // Confirm Password Field
                        CustomTextField(
                          label: 'Confirm Password',
                          placeholder: 'Re-enter new password',
                          isPassword: true,
                          controller: _confirmPasswordController,
                        ),
                        const SizedBox(height: 32),

                        // Set Password Button
                        CustomButton(
                          text: 'Set Password',
                          onPressed: _handleSetPassword,
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}