import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_text_field.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_auth.dart';
import '../data/model/request/req_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiProviderAuth _authApi = getIt<ApiProviderAuth>();
  
  bool isLoading = false;

  Future<void> _handleUpdatePassword() async {
    // Validate fields
    if (_currentPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showError('Please enter a new password');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('New password must be at least 6 characters');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('New passwords do not match');
      return;
    }

    if (_currentPasswordController.text == _newPasswordController.text) {
      _showError('New password must be different from current password');
      return;
    }

    setState(() => isLoading = true);

    try {
      final request = ChangePasswordReq(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      final response = await _authApi.changePassword(request);

      if (mounted) {
        _showSuccess(response.message);
        
        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        // Navigate back after short delay
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            context.go('/myprofile');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(_parseError(e));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('incorrect') || errorStr.contains('wrong') || errorStr.contains('invalid')) {
      return 'Current password is incorrect';
    }
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Session expired. Please login again';
    }
    
    return 'Failed to update password. Please try again.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/myprofile/changepassword'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Current Password
                  CustomTextField(
                    label: 'Current Password',
                    placeholder: 'Enter current password',
                    isPassword: true,
                    controller: _currentPasswordController,
                  ),
                  const SizedBox(height: 24),

                  // New Password
                  CustomTextField(
                    label: 'New Password',
                    placeholder: 'Enter new password',
                    isPassword: true,
                    controller: _newPasswordController,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Password must be at least 6 characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm New Password
                  CustomTextField(
                    label: 'Confirm New Password',
                    placeholder: 'Confirm new password',
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => context.go('/myprofile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            side: BorderSide(color: AppColors.inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 150,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _handleUpdatePassword(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}