import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/dashboard'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Today's Classes Section
              Text(
                'Today\'s Classes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Stats Cards
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Total Classes', value: '150')),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Classes Completed', value: '120')),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Classes Canceled', value: '30')),
                ],
              ),
              const SizedBox(height: 24),

              // Classes Table
              _buildClassesTable(),
              const SizedBox(height: 48),

              // Today's Attendance Section
              Text(
                'Today\'s Attendance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Attendance Stats
              Row(
                children: [
                  Expanded(child: StatCard(label: 'Total Tutors', value: '150')),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Tutors Present Today', value: '120')),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Tutors Late Today', value: '10')),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Tutors Absent Today', value: '30')),
                ],
              ),
              const SizedBox(height: 24),

              // Attendance Table
              _buildAttendanceTable(),
              const SizedBox(height: 48),

              // Recent Activity
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Class Name', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Time', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Assigned Tutor', style: _headerStyle())),
                Expanded(flex: 1, child: Text('Status', style: _headerStyle())),
              ],
            ),
          ),
          // Table Rows
          _buildClassRow('Algebra I', '10:00 AM - 11:00 AM', 'Ethan Harper', StatusType.info, 'Ongoing'),
          _buildClassRow('Physics Lab', '11:30 AM - 12:30 PM', 'Olivia Bennett', StatusType.success, 'Upcoming'),
          _buildClassRow('English Literature', '1:00 PM - 2:00 PM', 'Liam Foster', StatusType.error, 'Canceled'),
        ],
      ),
    );
  }

  Widget _buildClassRow(String name, String time, String tutor, StatusType statusType, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: _cellStyle())),
          Expanded(flex: 2, child: Text(time, style: _cellStyle())),
          Expanded(flex: 2, child: Text(tutor, style: _cellStyle().copyWith(color: AppColors.textSecondary))),
          Expanded(flex: 1, child: StatusBadge(text: status, type: statusType)),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Tutor Name', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Subject', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Last Check-in', style: _headerStyle())),
                Expanded(flex: 1, child: Text('Status', style: _headerStyle())),
              ],
            ),
          ),
          // Table Rows
          _buildAttendanceRow('Ethan Harper', 'Mathematics', '09:00 AM', StatusType.success, 'Present'),
          _buildAttendanceRow('Olivia Bennett', 'Physics', '09:05 AM', StatusType.success, 'Present'),
          _buildAttendanceRow('Noah Carter', 'Chemistry', 'N/A', StatusType.error, 'Absent'),
          _buildAttendanceRow('Ava Morgan', 'Biology', '09:10 AM', StatusType.success, 'Present'),
          _buildAttendanceRow('Liam Foster', 'English', 'N/A', StatusType.error, 'Late'),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(String name, String subject, String checkIn, StatusType statusType, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: _cellStyle())),
          Expanded(flex: 2, child: Text(subject, style: _cellStyle().copyWith(color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text(checkIn, style: _cellStyle())),
          Expanded(flex: 1, child: StatusBadge(text: status, type: statusType)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildActivityItem(Icons.check_circle, 'Ethan Harper checked in', 'Mathematics', true),
          const SizedBox(height: 16),
          _buildActivityItem(Icons.check_circle, 'Olivia Bennett checked in', 'Physics', true),
          const SizedBox(height: 16),
          _buildActivityItem(Icons.cancel, 'Noah Carter marked absent', 'Chemistry', false),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle, bool isSuccess) {
    return Row(
      children: [
        Icon(
          icon,
          color: isSuccess ? AppColors.statusGreen : AppColors.statusRed,
          size: 24,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _cellStyle()),
            Text(subtitle, style: _cellStyle().copyWith(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  TextStyle _headerStyle() {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  TextStyle _cellStyle() {
    return TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
    );
  }
}