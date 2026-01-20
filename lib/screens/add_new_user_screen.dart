import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'dart:math';

class AddNewUserScreen extends StatefulWidget {
  const AddNewUserScreen({Key? key}) : super(key: key);

  @override
  State<AddNewUserScreen> createState() => _AddNewUserScreenState();
}

class _AddNewUserScreenState extends State<AddNewUserScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _qualificationsController = TextEditingController();
  
  String? selectedDepartment;
  String selectedRole = 'Tutor';
  String generatedUserId = 'T001';
  String generatedPassword = '';
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    _generateCredentials();
  }

  void _generateCredentials() {
    // Generate random password
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    generatedPassword = String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    
    // Generate User ID based on role
    _updateUserId();
  }

  void _updateUserId() {
    setState(() {
      if (selectedRole == 'Admin') {
        generatedUserId = 'A${(Random().nextInt(900) + 100).toString().padLeft(3, '0')}';
      } else {
        generatedUserId = 'T${(Random().nextInt(900) + 100).toString().padLeft(3, '0')}';
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/account/new'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      'Add New User',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Full Name
                  CustomTextField(
                    label: 'Full Name',
                    placeholder: 'Enter full name',
                    controller: _fullNameController,
                  ),
                  const SizedBox(height: 24),

                  // Contact Number
                  CustomTextField(
                    label: 'Contact Number',
                    placeholder: 'Enter contact number',
                    controller: _contactController,
                  ),
                  const SizedBox(height: 24),

                  // Email Address
                  CustomTextField(
                    label: 'Email Address',
                    placeholder: 'Enter email address',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 24),

                  // Department
                  _buildDropdownField('Department', selectedDepartment, 
                    ['Math', 'Science', 'English', 'History', 'Physics'],
                    (value) => setState(() => selectedDepartment = value),
                  ),
                  const SizedBox(height: 24),

                  // Qualifications
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Qualifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qualificationsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter qualifications',
                          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Auto-Generated Credentials Section
                  Text(
                    'Auto-Generated Credentials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Role
                  _buildDropdownField('Account Role', selectedRole,
                    ['Tutor', 'Admin'],
                    (value) {
                      setState(() {
                        selectedRole = value!;
                        _updateUserId();
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // User ID
                  _buildReadOnlyFieldWithCopy('User ID', generatedUserId),
                  const SizedBox(height: 24),

                  // Password
                  _buildPasswordField(),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            side: BorderSide(color: AppColors.inputBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: CustomButton(
                          text: 'Save',
                          onPressed: () {
                            // Save user logic
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('User created successfully')),
                            );
                          },
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

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('Select $label'),
              isExpanded: true,
              icon: Icon(Icons.unfold_more, color: AppColors.textSecondary),
              items: items
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyFieldWithCopy(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value, style: TextStyle(fontSize: 16)),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 20, color: AppColors.textSecondary),
                onPressed: () => _copyToClipboard(value, label),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  showPassword ? generatedPassword : '••••••••',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => showPassword = !showPassword),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 20, color: AppColors.textSecondary),
                onPressed: () => _copyToClipboard(generatedPassword, 'Password'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }
}