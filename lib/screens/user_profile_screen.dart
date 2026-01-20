import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_button.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  
  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample user data
    final user = {
      'userId': 'T001',
      'name': 'Olivia Bennett',
      'role': 'Tutor',
      'email': 'olivia.bennett@email.com',
      'phone': '(555) 987-6543',
      'address': '123 Oak Street, Anytown, USA',
      'qualifications': 'Bachelor\'s Degree in Mathematics from XYZ University, 5+ years of experience teaching Algebra and Calculus to high school students.',
      'department': 'Mathematics',
      'hireDate': '2021-08-15',
      'status': 'Active',
      'totalAttendance': 150,
      'leavesTaken': 5,
      'attendanceRate': '96%',
    };

    final classes = [
      {'name': 'Algebra 101', 'schedule': '2024-07-20 09:00 - 10:00', 'school': 'Tech Academy'},
      {'name': 'Calculus I', 'schedule': '2024-07-21 10:00 - 11:00', 'school': 'Math Institute'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/account/profile'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'User Profile',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Icon(Icons.person, size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    user['role'] as String,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Personal Information Section
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Full Name', user['name'] as String, 'Contact Number', user['phone'] as String),
                    const Divider(height: 32),
                    _buildInfoRow('Email', user['email'] as String, 'Address', user['address'] as String),
                    const Divider(height: 32),
                    _buildSingleInfoRow('Qualifications', user['qualifications'] as String),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Employment Details Section
              Text(
                'Employment Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('User ID', user['userId'] as String, 'Status', user['status'] as String),
                    const Divider(height: 32),
                    _buildInfoRow('Department', user['department'] as String, 'Hire Date', user['hireDate'] as String),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Edit Button
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 100,
                  child: CustomButton(
                    text: 'Edit',
                    onPressed: () {
                      // Navigate to edit screen
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Attendance Summary Section
              Text(
                'Attendance Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Total Attendance', value: user['totalAttendance'].toString())),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Leaves Taken', value: user['leavesTaken'].toString())),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Average Attendance Rate', value: user['attendanceRate'] as String)),
                ],
              ),
              const SizedBox(height: 32),

              // Assigned Classes Section
              Text(
                'Assigned Classes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildClassesTable(classes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value1, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildClassesTable(List<Map<String, String>> classes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Class Name', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: Text('Schedule', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('School', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          // Rows
          ...classes.map((c) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(c['name']!)),
                Expanded(flex: 3, child: Text(c['schedule']!, style: TextStyle(color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text(c['school']!, style: TextStyle(color: AppColors.textSecondary))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}