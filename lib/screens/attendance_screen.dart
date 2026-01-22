import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_attendance.dart';
import '../data/api/api_provider_users.dart';
import '../data/api/api_provider_course.dart';
import '../data/api/api_provider_school.dart';
import '../data/model/response/res_attendance.dart';
import '../data/model/response/res_course.dart';
import '../data/model/response/res_school.dart';
import '../data/model/response/res_user.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiProviderAttendance _attendanceApi = getIt<ApiProviderAttendance>();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();
  final ApiProviderCourse _courseApi = getIt<ApiProviderCourse>();
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();

  String? selectedTutorId;
  String? selectedCourseId;
  String? selectedSchoolId;
  String? selectedStatus;
  String searchQuery = '';

  List<AttendanceRes> attendances = [];
  Map<String, CourseRes> coursesMap = {};
  Map<String, SchoolRes> schoolsMap = {};
  Map<String, UserResponse> tutorsMap = {};
  
  // Filter options
  List<UserResponse> tutorOptions = [];
  List<CourseRes> courseOptions = [];
  List<SchoolRes> schoolOptions = [];

  bool isLoading = true;
  bool isExporting = false;
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
      // Load filter options in parallel
      final futures = await Future.wait([
        _usersApi.getUsers(role: 'tutor'),
        _courseApi.getCourses(),
        _schoolApi.getSchools(),
      ]);

      final usersRes = futures[0] as dynamic;
      final coursesRes = futures[1] as dynamic;
      final schoolsRes = futures[2] as dynamic;

      tutorOptions = usersRes.items;
      courseOptions = coursesRes.items;
      schoolOptions = schoolsRes.items;

      // Build lookup maps
      for (var tutor in tutorOptions) {
        if (tutor.id != null) {
          tutorsMap[tutor.id!] = tutor;
        }
      }
      for (var course in courseOptions) {
        if (course.id != null) {
          coursesMap[course.id!] = course;
        }
      }
      for (var school in schoolOptions) {
        if (school.id != null) {
          schoolsMap[school.id!] = school;
        }
      }

      // Load attendances
      await _loadAttendances();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadAttendances() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _attendanceApi.getAttendances(
        tutorId: selectedTutorId,
        courseId: selectedCourseId,
        schoolId: selectedSchoolId,
      );

      // Merge lookup maps from response if available
      if (response.courses != null) {
        coursesMap.addAll(response.courses!);
      }
      if (response.schools != null) {
        schoolsMap.addAll(response.schools!);
      }

      setState(() {
        attendances = response.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _exportRecords() async {
    setState(() => isExporting = true);

    try {
      final bytes = await _attendanceApi.exportAttendances(
        courseId: selectedCourseId ?? '',
        tutorId: selectedTutorId ?? '',
        schoolId: selectedSchoolId ?? '',
        startDate: '',
        endDate: '',
        format: 'csv',
      );

      // Handle file download (simplified - you may need to implement actual file saving)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export completed! ${bytes.length} bytes downloaded.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isExporting = false);
    }
  }

  String _getStatusFromAttendance(AttendanceRes attendance) {
    if (!attendance.checked) {
      return 'Absent';
    }
    
    if (attendance.checkInTime != null && attendance.timestamp != null) {
      try {
        final scheduledStart = DateTime.fromMillisecondsSinceEpoch(attendance.timestamp.start.toInt());
        final checkIn = DateTime.parse(attendance.checkInTime!);
        
        // If checked in more than 5 minutes late
        if (checkIn.isAfter(scheduledStart.add(Duration(minutes: 5)))) {
          return 'Late';
        }
      } catch (e) {
        // If parsing fails, just check if checked
      }
    }
    
    return 'Present';
  }

  StatusType _getStatusType(String status) {
    switch (status) {
      case 'Present':
        return StatusType.success;
      case 'Absent':
        return StatusType.error;
      case 'Late':
        return StatusType.error;
      default:
        return StatusType.success;
    }
  }

  String _formatTimestamp(CourseTimestampRes? timestamp) {
    if (timestamp == null) return '-';
    
    try {
      final start = DateTime.fromMillisecondsSinceEpoch(timestamp.start.toInt());
      final end = DateTime.fromMillisecondsSinceEpoch(timestamp.end.toInt());
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      
      return '${dateFormat.format(start)}\n${timeFormat.format(start)} - ${timeFormat.format(end)}';
    } catch (e) {
      return '-';
    }
  }

  String _formatCheckInTime(String? checkInTime) {
    if (checkInTime == null) return '-';
    
    try {
      final dateTime = DateTime.parse(checkInTime);
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      
      return '${dateFormat.format(dateTime)}\n${timeFormat.format(dateTime)}';
    } catch (e) {
      return checkInTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/attendance'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Text(
                'Tutor Attendance Records',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
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
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Filters
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildTutorDropdown(),
                  _buildCourseDropdown(),
                  _buildSchoolDropdown(),
                  _buildStatusDropdown(),
                  // Refresh Button
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _loadAttendances,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              if (isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: Text('Retry')),
                      ],
                    ),
                  ),
                )
              else
                _buildAttendanceTable(),
              const SizedBox(height: 24),

              // Export Button
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isExporting ? null : () => _exportRecords(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isExporting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Export Records',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildTutorDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTutorId,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tutor', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          icon: Container(),
          items: [
            DropdownMenuItem(value: null, child: Text('All Tutors')),
            ...tutorOptions.map((tutor) => DropdownMenuItem(
              value: tutor.id,
              child: Text(tutor.name, style: TextStyle(fontSize: 14)),
            )),
          ],
          onChanged: (value) {
            setState(() => selectedTutorId = value);
            _loadAttendances();
          },
        ),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCourseId,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Class', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          icon: Container(),
          items: [
            DropdownMenuItem(value: null, child: Text('All Classes')),
            ...courseOptions.map((course) => DropdownMenuItem(
              value: course.id,
              child: Text(course.name, style: TextStyle(fontSize: 14)),
            )),
          ],
          onChanged: (value) {
            setState(() => selectedCourseId = value);
            _loadAttendances();
          },
        ),
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSchoolId,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('School', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          icon: Container(),
          items: [
            DropdownMenuItem(value: null, child: Text('All Schools')),
            ...schoolOptions.map((school) => DropdownMenuItem(
              value: school.id,
              child: Text(school.name, style: TextStyle(fontSize: 14)),
            )),
          ],
          onChanged: (value) {
            setState(() => selectedSchoolId = value);
            _loadAttendances();
          },
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          icon: Container(),
          items: [
            DropdownMenuItem(value: null, child: Text('All Status')),
            DropdownMenuItem(value: 'Present', child: Text('Present')),
            DropdownMenuItem(value: 'Absent', child: Text('Absent')),
            DropdownMenuItem(value: 'Late', child: Text('Late')),
          ],
          onChanged: (value) {
            setState(() => selectedStatus = value);
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    // Filter attendances based on search and status
    final filteredAttendances = attendances.where((attendance) {
      // Status filter (client-side since API doesn't support status filter)
      if (selectedStatus != null) {
        final status = _getStatusFromAttendance(attendance);
        if (status != selectedStatus) return false;
      }

      // Search filter
      if (searchQuery.isNotEmpty) {
        final tutor = tutorsMap[attendance.tutorId];
        final course = coursesMap[attendance.courseId];
        final school = schoolsMap[attendance.schoolId];
        
        final tutorName = tutor?.name.toLowerCase() ?? '';
        final courseName = course?.name.toLowerCase() ?? '';
        final schoolName = school?.name.toLowerCase() ?? '';
        
        if (!tutorName.contains(searchQuery) &&
            !courseName.contains(searchQuery) &&
            !schoolName.contains(searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();

    if (filteredAttendances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('No attendance records found', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            ],
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
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Tutor', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Class', style: _headerStyle())),
                Expanded(flex: 2, child: Text('School', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Scheduled Time', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Check-in Time', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Status', style: _headerStyle())),
                Expanded(flex: 3, child: Text('Notes', style: _headerStyle())),
              ],
            ),
          ),
          // Table Rows
          ...filteredAttendances.map((attendance) => _buildRow(attendance)),
        ],
      ),
    );
  }

  Widget _buildRow(AttendanceRes attendance) {
    final tutor = tutorsMap[attendance.tutorId];
    final course = coursesMap[attendance.courseId];
    final school = schoolsMap[attendance.schoolId];
    final status = _getStatusFromAttendance(attendance);
    final statusType = _getStatusType(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              tutor?.name ?? attendance.tutorId,
              style: _cellStyle(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              course?.name ?? attendance.courseId,
              style: _cellStyle().copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              school?.name ?? attendance.schoolId,
              style: _cellStyle().copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatTimestamp(attendance.timestamp),
              style: _cellStyle(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCheckInTime(attendance.checkInTime),
              style: _cellStyle(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(text: status, type: statusType),
            ),
          ),
        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}