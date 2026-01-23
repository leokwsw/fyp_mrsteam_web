import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_course.dart';
import '../data/api/api_provider_school.dart';
import '../data/api/api_provider_users.dart';
import '../data/model/response/res_course.dart';
import '../data/model/response/res_school.dart';
import '../data/model/response/res_user.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({Key? key}) : super(key: key);

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final ApiProviderCourse _courseApi = getIt<ApiProviderCourse>();
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();

  late DateTime currentDateTimeHK;
  String selectedTab = 'Upcoming';
  String? selectedCourseId;
  String? selectedSchoolId;
  String? selectedTutorId;
  String? selectedStatus;

  List<CourseRes> allCourses = [];
  Map<String, SchoolRes> schoolsMap = {};
  Map<String, UserResponse> tutorsMap = {};
  
  // Filter options
  List<CourseRes> courseOptions = [];
  List<SchoolRes> schoolOptions = [];
  List<UserResponse> tutorOptions = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    currentDateTimeHK = _getHongKongTime();
    _loadData();
    
    Future.delayed(Duration.zero, () {
      _startTimeUpdate();
    });
  }

  DateTime _getHongKongTime() {
    final now = DateTime.now().toUtc();
    return now.add(Duration(hours: 8));
  }

  void _startTimeUpdate() {
    Future.delayed(Duration(minutes: 1), () {
      if (mounted) {
        setState(() {
          currentDateTimeHK = _getHongKongTime();
        });
        _startTimeUpdate();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _courseApi.getCourses(),
        _schoolApi.getSchools(),
        _usersApi.getUsers(role: 'tutor'),
      ]);

      final coursesRes = futures[0] as CourseListRes;
      final schoolsRes = futures[1] as SchoolListRes;
      final tutorsRes = futures[2] as dynamic;

      courseOptions = coursesRes.items;
      schoolOptions = schoolsRes.items;
      tutorOptions = tutorsRes.items;

      // Build lookup maps
      for (var school in schoolOptions) {
        if (school.id != null) {
          schoolsMap[school.id!] = school;
        }
      }
      for (var tutor in tutorOptions) {
        if (tutor.id != null) {
          tutorsMap[tutor.id!] = tutor;
        }
      }

      setState(() {
        allCourses = coursesRes.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Get filtered class list
  List<ClassListItem> get filteredClasses {
    List<ClassListItem> classList = [];

    for (var course in allCourses) {
      // Apply filters
      if (selectedCourseId != null && selectedCourseId != 'All' && course.id != selectedCourseId) {
        continue;
      }
      if (selectedSchoolId != null && selectedSchoolId != 'All' && course.schoolId != selectedSchoolId) {
        continue;
      }
      if (selectedTutorId != null && selectedTutorId != 'All' && course.tutorId != selectedTutorId) {
        continue;
      }

      // Process each timestamp
      for (var timestamp in course.timestamps) {
        final startDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.start.toInt());
        final endDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.end.toInt());
        
        // Apply tab filter
        final now = currentDateTimeHK;
        if (selectedTab == 'Upcoming' && startDateTime.isBefore(now)) continue;
        if (selectedTab == 'Past' && startDateTime.isAfter(now)) continue;

        // Determine status
        String status = 'Scheduled';
        if (course.isDeleted == true) {
          status = 'Canceled';
        } else if (endDateTime.isBefore(now)) {
          status = 'Completed';
        }

        // Apply status filter
        if (selectedStatus != null && selectedStatus != 'All' && status != selectedStatus) {
          continue;
        }

        final school = schoolsMap[course.schoolId];
        final tutor = tutorsMap[course.tutorId];

        classList.add(ClassListItem(
          courseId: course.id ?? '',
          className: course.name,
          schoolName: school?.name ?? 'Unknown School',
          tutorName: tutor?.name ?? 'Unknown Tutor',
          date: DateFormat('dd/MM/yyyy').format(startDateTime),
          time: '${_formatTime(startDateTime)} - ${_formatTime(endDateTime)}',
          location: course.room,
          status: status,
          startDateTime: startDateTime,
        ));
      }
    }

    // Sort by date
    classList.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    
    return classList;
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/class'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title with Current Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Class',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          _formatHongKongDateTime(currentDateTimeHK),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(GMT+8)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // View Toggle Buttons
              Row(
                children: [
                  _buildViewButton('Calendar View', false),
                  const SizedBox(width: 16),
                  _buildViewButton('List View', true),
                ],
              ),
              const SizedBox(height: 24),

              // Tabs
              Row(
                children: [
                  _buildTab('Upcoming'),
                  const SizedBox(width: 32),
                  _buildTab('Past'),
                  const SizedBox(width: 32),
                  _buildTab('All'),
                ],
              ),
              const SizedBox(height: 32),

              // Filters and New Class Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildCourseDropdown(),
                      _buildSchoolDropdown(),
                      _buildTutorDropdown(),
                      _buildStatusDropdown(),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _loadData,
                        tooltip: 'Refresh',
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        child: CustomButton(
                          text: 'New Class',
                          onPressed: () => context.push('/class/create'),
                        ),
                      ),
                    ],
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
                        Text('Error loading classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: Text('Retry')),
                      ],
                    ),
                  ),
                )
              else
                _buildClassList(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHongKongDateTime(DateTime dt) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final dayName = days[dt.weekday % 7];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');

    return '$dayName, $day/$month/${dt.year} $hour:$minute';
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
          onChanged: (value) => setState(() => selectedCourseId = value),
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
          onChanged: (value) => setState(() => selectedSchoolId = value),
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
          onChanged: (value) => setState(() => selectedTutorId = value),
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
            DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
            DropdownMenuItem(value: 'Completed', child: Text('Completed')),
            DropdownMenuItem(value: 'Canceled', child: Text('Canceled')),
          ],
          onChanged: (value) => setState(() => selectedStatus = value),
        ),
      ),
    );
  }

  Widget _buildViewButton(String text, bool isListView) {
    bool isActive = isListView;
    return GestureDetector(
      onTap: () {
        if (!isListView) {
          context.go('/class');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text) {
    bool isActive = selectedTab == text;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = text),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 60,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    final classes = filteredClasses;
    
    if (classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No classes found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(color: AppColors.textSecondary),
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildHeaderCell('Class Name')),
                Expanded(flex: 2, child: _buildHeaderCell('School')),
                Expanded(flex: 2, child: _buildHeaderCell('Tutor')),
                Expanded(flex: 1, child: _buildHeaderCell('Date')),
                Expanded(flex: 1, child: _buildHeaderCell('Time')),
                Expanded(flex: 1, child: _buildHeaderCell('Location')),
                Expanded(flex: 1, child: _buildHeaderCell('Status')),
              ],
            ),
          ),
          // Table Body
          ...classes.map((classItem) => _buildClassRow(classItem)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildClassRow(ClassListItem classItem) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              classItem.className,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              classItem.schoolName,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              classItem.tutorName,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              classItem.date,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              classItem.time,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              classItem.location,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildStatusBadge(classItem.status),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Canceled':
        color = Color(0xFFB71C1C);
        break;
      case 'Completed':
        color = Colors.green;
        break;
      default:
        color = Color(0xFF1E3A5F);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ClassListItem {
  final String courseId;
  final String className;
  final String schoolName;
  final String tutorName;
  final String date;
  final String time;
  final String location;
  final String status;
  final DateTime startDateTime;

  ClassListItem({
    required this.courseId,
    required this.className,
    required this.schoolName,
    required this.tutorName,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.startDateTime,
  });
}