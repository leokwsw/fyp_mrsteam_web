import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../core/config/get_it.dart';
import '../../core/util/app_preferences.dart';
import '../../data/api/api_provider_auth.dart';
import '../../data/model/request/req_login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiProviderAuth _authApi = getIt<ApiProviderAuth>();

  String selectedRole = 'staff'; // Default role
  bool isLoading = false;
  String? errorMessage;

  final List<Map<String, String>> roles = [
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'staff', 'label': 'Staff'},
    {'value': 'tutor', 'label': 'Tutor'},
  ];

  Future<void> _handleLogin() async {
    // Validate input
    if (_userIdController.text.trim().isEmpty) {
      _showError('Please enter your User ID');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final request = LoginReq(
        _userIdController.text.trim(),
        _passwordController.text,
        role: selectedRole,
      );

      final response = await _authApi.login(request);

      // Store tokens in preferences
      await AppPreferences.setAccessToken(response.accessToken);
      await AppPreferences.setRefreshToken(response.refreshToken);
      await AppPreferences.setSessionId(response.sessionId);
      await AppPreferences.setUserId(response.user.id ?? '');

      if (mounted) {
        // Navigate to dashboard after successful login
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _parseError(e);
          isLoading = false;
        });
      }
    }
  }

  String _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Invalid username or password';
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your connection';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again';
    }
    
    return 'Login failed. Please try again';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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

                        // Error Message
                        if (errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

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
                        const SizedBox(height: 24),

                        // Role Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.inputBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                  items: roles.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role['value'],
                                      child: Text(
                                        role['label']!,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              selectedRole = value;
                                            });
                                          }
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        isLoading
                            ? SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            : CustomButton(
                                text: 'Login',
                                onPressed: () => _handleLogin(),
                              ),
                        const SizedBox(height: 16),

                        // Forgot Password Link
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
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