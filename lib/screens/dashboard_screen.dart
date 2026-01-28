import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_statistics.dart';
import '../data/api/api_provider_course.dart';
import '../data/api/api_provider_attendance.dart';
import '../data/api/api_provider_users.dart';
import '../data/api/api_provider_school.dart';
import '../data/model/response/res_statistics.dart';
import '../data/model/response/res_course.dart';
import '../data/model/response/res_attendance.dart';
import '../data/model/response/res_user.dart';
import '../data/model/response/res_school.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiProviderStatistics _statsApi = getIt<ApiProviderStatistics>();
  final ApiProviderCourse _courseApi = getIt<ApiProviderCourse>();
  final ApiProviderAttendance _attendanceApi = getIt<ApiProviderAttendance>();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();

  StatisticsDashboardRes? dashboardStats;
  List<CourseRes> todayClasses = [];
  List<AttendanceRes> todayAttendance = [];
  Map<String, UserResponse> tutorsMap = {};
  Map<String, SchoolRes> schoolsMap = {};
  Map<String, CourseRes> coursesMap = {};

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
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final dateFormat = DateFormat('yyyy-MM-dd');

      // Load all data in parallel
      final futures = await Future.wait([
        _statsApi.getDashboardStatistics(
          tutorId: '',
          schoolId: '',
          startDate: dateFormat.format(startOfDay),
          endDate: dateFormat.format(endOfDay),
        ),
        _courseApi.getCourses(),
        _attendanceApi.getAttendances(
          startDate: dateFormat.format(startOfDay),
          endDate: dateFormat.format(endOfDay),
        ),
        _usersApi.getUsers(role: 'tutor'),
        _schoolApi.getSchools(),
      ]);

      final statsRes = futures[0] as StatisticsDashboardRes;
      final coursesRes = futures[1] as CourseListRes;
      final attendanceRes = futures[2] as AttendanceListRes;
      final tutorsRes = futures[3] as dynamic;
      final schoolsRes = futures[4] as SchoolListRes;

      // Build lookup maps
      tutorsMap.clear();
      schoolsMap.clear();
      coursesMap.clear();

      for (var tutor in tutorsRes.items) {
        if (tutor.id != null) {
          tutorsMap[tutor.id!] = tutor;
        }
      }
      for (var school in schoolsRes.items) {
        if (school.id != null) {
          schoolsMap[school.id!] = school;
        }
      }
      for (var course in coursesRes.items) {
        if (course.id != null) {
          coursesMap[course.id!] = course;
        }
      }

      // Filter today's classes
      final todayCourses = coursesRes.items.where((course) {
        for (var ts in course.timestamps) {
          final start = DateTime.fromMillisecondsSinceEpoch(ts.start.toInt());
          if (start.year == today.year &&
              start.month == today.month &&
              start.day == today.day) {
            return true;
          }
        }
        return false;
      }).toList();

      setState(() {
        dashboardStats = statsRes;
        todayClasses = todayCourses;
        todayAttendance = attendanceRes.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatTime(num timestamp) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '-';
    }
  }

  String _getClassStatus(CourseRes course) {
    if (course.isDeleted == true) return 'Canceled';
    
    final now = DateTime.now();
    for (var ts in course.timestamps) {
      final start = DateTime.fromMillisecondsSinceEpoch(ts.start.toInt());
      final end = DateTime.fromMillisecondsSinceEpoch(ts.end.toInt());
      
      if (now.isAfter(start) && now.isBefore(end)) {
        return 'Ongoing';
      } else if (now.isBefore(start)) {
        return 'Upcoming';
      }
    }
    return 'Completed';
  }

  StatusType _getClassStatusType(String status) {
    switch (status) {
      case 'Ongoing':
        return StatusType.info;
      case 'Upcoming':
        return StatusType.success;
      case 'Canceled':
        return StatusType.error;
      default:
        return StatusType.success;
    }
  }

  String _getAttendanceStatus(AttendanceRes attendance) {
    if (!attendance.checked) return 'Absent';
    
    if (attendance.checkInTime != null) {
      try {
        final scheduledStart = DateTime.fromMillisecondsSinceEpoch(attendance.timestamp.start.toInt());
        final checkIn = DateTime.parse(attendance.checkInTime!);
        
        if (checkIn.isAfter(scheduledStart.add(Duration(minutes: 5)))) {
          return 'Late';
        }
      } catch (e) {}
    }
    return 'Present';
  }

  StatusType _getAttendanceStatusType(String status) {
    switch (status) {
      case 'Present':
        return StatusType.success;
      case 'Late':
        return StatusType.error;
      case 'Absent':
        return StatusType.error;
      default:
        return StatusType.success;
    }
  }

  // Filter attendance to only show past classes
  List<AttendanceRes> get filteredAttendance {
    final now = DateTime.now();
    return todayAttendance.where((attendance) {
      try {
        final scheduledStart = DateTime.fromMillisecondsSinceEpoch(attendance.timestamp.start.toInt());
        // Only include if the class has already started
        return scheduledStart.isBefore(now);
      } catch (e) {
        return true;
      }
    }).toList()
      ..sort((a, b) {
        // Sort by start time descending (most recent first)
        return b.timestamp.start.compareTo(a.timestamp.start);
      });
  }

  // Calculate attendance stats from filtered attendance (past classes only)
  Map<String, int> get attendanceStatsFromFiltered {
    final filtered = filteredAttendance;
    final present = filtered.where((a) => a.checked).length;
    final absent = filtered.where((a) => !a.checked).length;
    final total = filtered.length;
    final rate = total > 0 ? (present / total * 100).round() : 0;
    
    return {
      'present': present,
      'absent': absent,
      'total': total,
      'rate': rate,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/dashboard'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/dashboard'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading dashboard'),
              const SizedBox(height: 8),
              Text(errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    final stats = dashboardStats!;
    final courseStats = stats.course.summary;
    final userStats = stats.users;
    final attendanceFromFiltered = attendanceStatsFromFiltered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/dashboard'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title with Refresh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                  ),
                ],
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
                  Expanded(
                    child: StatCard(
                      label: 'Total Classes',
                      value: courseStats.total.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Today\'s Classes',
                      value: todayClasses.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Completed',
                      value: todayClasses.where((c) => _getClassStatus(c) == 'Completed').length.toString(),
                    ),
                  ),
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

              // Attendance Stats - using filtered stats (past classes only)
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Tutors',
                      value: userStats.totalTutors.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Present Today',
                      value: attendanceFromFiltered['present'].toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Absent Today',
                      value: attendanceFromFiltered['absent'].toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      label: 'Attendance Rate',
                      value: '${attendanceFromFiltered['rate']}%',
                    ),
                  ),
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
    if (todayClasses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            'No classes scheduled for today',
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
          ...todayClasses.take(5).map((course) {
            final tutor = tutorsMap[course.tutorId];
            final status = _getClassStatus(course);
            final statusType = _getClassStatusType(status);
            
            String timeStr = '-';
            if (course.timestamps.isNotEmpty) {
              final ts = course.timestamps.first;
              timeStr = '${_formatTime(ts.start)} - ${_formatTime(ts.end)}';
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(course.name, style: _cellStyle())),
                  Expanded(flex: 2, child: Text(timeStr, style: _cellStyle())),
                  Expanded(
                    flex: 2,
                    child: Text(
                      tutor?.name ?? 'Unassigned',
                      style: _cellStyle().copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(flex: 1, child: StatusBadge(text: status, type: statusType)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    // Use filtered attendance (only past classes)
    final pastAttendance = filteredAttendance;

    if (pastAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            'No attendance records for today',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Tutor Name', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Class', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Check-in Time', style: _headerStyle())),
                Expanded(flex: 1, child: Text('Status', style: _headerStyle())),
              ],
            ),
          ),
          ...pastAttendance.take(5).map((attendance) {
            final tutor = tutorsMap[attendance.tutorId];
            final course = coursesMap[attendance.courseId];
            final status = _getAttendanceStatus(attendance);
            final statusType = _getAttendanceStatusType(status);
            
            String checkInTime = '-';
            if (attendance.checkInTime != null) {
              try {
                final dt = DateTime.parse(attendance.checkInTime!);
                checkInTime = DateFormat('hh:mm a').format(dt);
              } catch (e) {}
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(tutor?.name ?? '-', style: _cellStyle())),
                  Expanded(
                    flex: 2,
                    child: Text(
                      course?.name ?? '-',
                      style: _cellStyle().copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(flex: 2, child: Text(checkInTime, style: _cellStyle())),
                  Expanded(flex: 1, child: StatusBadge(text: status, type: statusType)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Use filtered attendance (only past classes)
    final pastAttendance = filteredAttendance;

    // Build activity from past attendance only
    final recentActivities = pastAttendance.take(5).map((attendance) {
      final tutor = tutorsMap[attendance.tutorId];
      final course = coursesMap[attendance.courseId];
      final isCheckedIn = attendance.checked;
      
      return {
        'icon': isCheckedIn ? Icons.check_circle : Icons.cancel,
        'title': isCheckedIn 
            ? '${tutor?.name ?? 'Tutor'} checked in'
            : '${tutor?.name ?? 'Tutor'} marked absent',
        'subtitle': course?.name ?? 'Class',
        'isSuccess': isCheckedIn,
      };
    }).toList();

    if (recentActivities.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No recent activity',
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: recentActivities.map((activity) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(
                  activity['icon'] as IconData,
                  color: (activity['isSuccess'] as bool) 
                      ? AppColors.statusGreen 
                      : AppColors.statusRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity['title'] as String, style: _cellStyle()),
                    Text(
                      activity['subtitle'] as String,
                      style: _cellStyle().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
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