import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_button.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_users.dart';
import '../data/api/api_provider_attendance.dart';
import '../data/api/api_provider_course.dart';
import '../data/api/api_provider_school.dart';
import '../data/model/response/res_user.dart';
import '../data/model/response/res_attendance.dart';
import '../data/model/response/res_course.dart';
import '../data/model/response/res_school.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();
  final ApiProviderAttendance _attendanceApi = getIt<ApiProviderAttendance>();
  final ApiProviderCourse _courseApi = getIt<ApiProviderCourse>();
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();

  UserResponse? user;
  List<CourseRes> assignedClasses = [];
  Map<String, SchoolRes> schoolsMap = {};
  
  // Attendance stats
  int totalAttendance = 0;
  int presentCount = 0;
  int absentCount = 0;
  String attendanceRate = '0%';

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load all data in parallel
      final futures = await Future.wait([
        _usersApi.getUserById(widget.userId),
        _courseApi.getCourses(tutorId: widget.userId),
        _attendanceApi.getAttendances(tutorId: widget.userId),
        _schoolApi.getSchools(),
      ]);

      final userRes = futures[0] as UserResponse;
      final coursesRes = futures[1] as CourseListRes;
      final attendanceRes = futures[2] as AttendanceListRes;
      final schoolsRes = futures[3] as SchoolListRes;

      // Build schools map
      for (var school in schoolsRes.items) {
        if (school.id != null) {
          schoolsMap[school.id!] = school;
        }
      }

      // Calculate attendance stats
      final attendances = attendanceRes.items;
      final present = attendances.where((a) => a.checked).length;
      final absent = attendances.where((a) => !a.checked).length;
      final total = attendances.length;
      final rate = total > 0 ? (present / total * 100).toStringAsFixed(0) : '0';

      setState(() {
        user = userRes;
        assignedClasses = coursesRes.items;
        totalAttendance = total;
        presentCount = present;
        absentCount = absent;
        attendanceRate = '$rate%';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _capitalizeFirst(String? text) {
    if (text == null || text.isEmpty) return '-';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatSchedule(List<CourseTimestampRes> timestamps) {
    if (timestamps.isEmpty) return '-';
    try {
      final ts = timestamps.first;
      final start = DateTime.fromMillisecondsSinceEpoch(ts.start.toInt());
      final end = DateTime.fromMillisecondsSinceEpoch(ts.end.toInt());
      return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} '
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/account'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/account'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading user profile'),
              const SizedBox(height: 8),
              Text(errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/account'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and Title
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => context.go('/account'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'User Profile',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '-',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _capitalizeFirst(user?.role),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
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
                    _buildInfoRow('Full Name', user?.name ?? '-', 'Username', user?.username ?? '-'),
                    const Divider(height: 32),
                    _buildInfoRow('Email', user?.email ?? '-', 'Status', user?.isActive == true ? 'Active' : 'Inactive'),
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
                    _buildInfoRow('User ID', user?.id ?? '-', 'Role', _capitalizeFirst(user?.role)),
                    const Divider(height: 32),
                    _buildInfoRow('Created At', _formatDate(user?.createdAt), 'Last Updated', _formatDate(user?.updatedAt)),
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
                    onPressed: () => context.push('/account/user/${widget.userId}/edit'),
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
                  Expanded(child: StatCard(label: 'Total Attendance', value: totalAttendance.toString())),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Present', value: presentCount.toString())),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Absent', value: absentCount.toString())),
                  const SizedBox(width: 16),
                  Expanded(child: StatCard(label: 'Attendance Rate', value: attendanceRate)),
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
              _buildClassesTable(),
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

  Widget _buildClassesTable() {
    if (assignedClasses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            'No classes assigned',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

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
          ...assignedClasses.map((course) {
            final school = schoolsMap[course.schoolId];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(course.name)),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatSchedule(course.timestamps),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      school?.name ?? '-',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}