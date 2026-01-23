import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String? email;
  final String? resetToken;
  
  const SetNewPasswordScreen({
    Key? key,
    this.email,
    this.resetToken,
  }) : super(key: key);

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool _isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _handleSetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate passwords
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (!_isValidPassword(newPassword)) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters with uppercase, lowercase, and number';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement API call when backend endpoint is available
      // Example:
      // final authProvider = getIt<ApiProviderAuth>();
      // final response = await authProvider.setNewPassword(
      //   SetNewPasswordReq(
      //     email: widget.email,
      //     token: widget.resetToken,
      //     newPassword: newPassword,
      //   ),
      // );
      
      // Simulate API call delay for now
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset successfully! Please login with your new password.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to login
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to reset password. Please try again.';
        });
      }
    }
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
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: _isLoading ? null : () => context.pop(),
                    ),
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

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Password Requirements Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password requirements:',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

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
                          text: _isLoading ? 'Setting Password...' : 'Set Password',
                          onPressed: _isLoading ? () {} : () => _handleSetPassword(),
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