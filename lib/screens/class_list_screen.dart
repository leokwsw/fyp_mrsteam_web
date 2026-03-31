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
import '../data/model/request/req_school.dart';
import '../widgets/class_details_dialog.dart';

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
    return now.add(const Duration(hours: 8));
  }

  void _startTimeUpdate() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        setState(() {
          currentDateTimeHK = _getHongKongTime();
        });
        _startTimeUpdate();
      }
    });
  }

  Theme _buildDropdownTheme({required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: const Color(0xFFF5F5F5),
        focusColor: Colors.transparent,
      ),
      child: child,
    );
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

      // ===== Debug logs: parsed result =====
      debugPrint('=== parsed courses === count=${coursesRes.items.length}');
      if (coursesRes.items.isNotEmpty) {
        final c = coursesRes.items.first;
        debugPrint('first.id=${c.id}');
        debugPrint('first.name=${c.name}');
        debugPrint('first.courseCode=${c.courseCode}');
        debugPrint('first.subjectCode(getter)=${c.subjectCode}');
      }

      courseOptions = coursesRes.items;
      schoolOptions = schoolsRes.items;
      tutorOptions = tutorsRes.items;

      // Validate selected values exist in options
      if (selectedCourseId != null &&
          !courseOptions.any((c) => c.id == selectedCourseId)) {
        selectedCourseId = null;
      }
      if (selectedSchoolId != null &&
          !schoolOptions.any((s) => s.id == selectedSchoolId)) {
        selectedSchoolId = null;
      }
      if (selectedTutorId != null &&
          !tutorOptions.any((t) => t.id == selectedTutorId)) {
        selectedTutorId = null;
      }
      if (selectedStatus != null &&
          !const {'Scheduled', 'Completed', 'Canceled'}
              .contains(selectedStatus)) {
        selectedStatus = null;
      }

      // Clear old map first (avoid stale data)
      schoolsMap.clear();
      tutorsMap.clear();

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
    } catch (e, st) {
      debugPrint('[_loadData] error: $e');
      debugPrint(st.toString());
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Show Create School Dialog
  void _showCreateSchoolDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateSchoolDialog(
        onSchoolCreated: (newSchool) {
          setState(() {
            schoolOptions.add(newSchool);
            if (newSchool.id != null) {
              schoolsMap[newSchool.id!] = newSchool;
              selectedSchoolId = newSchool.id;
            }
          });
        },
      ),
    );
  }

  // Show Class Details Dialog
  void _showClassDetails(ClassListItem classItem) {
    showDialog(
      context: context,
      builder: (context) => ClassDetailsDialog(
        courseId: classItem.courseId,
        className: classItem.className,
        schoolName: classItem.schoolName,
        date: classItem.date,
        time: classItem.time,
        tutorName: classItem.tutorName,
        room: classItem.room,
        status: classItem.status,
        overview: classItem.overview,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Canceled':
        return const Color(0xFFB71C1C);
      case 'Completed':
        return Colors.green;
      default:
        return const Color(0xFF1E3A5F);
    }
  }

  // Get filtered class list
  List<ClassListItem> get filteredClasses {
    List<ClassListItem> classList = [];

    for (var course in allCourses) {
      // Apply filters (All == null)
      if (selectedCourseId != null && course.id != selectedCourseId) continue;
      if (selectedSchoolId != null && course.schoolId != selectedSchoolId) continue;
      if (selectedTutorId != null && course.tutorId != selectedTutorId) continue;

      // Build display name: courseCode + className
      final code = course.courseCode.trim();
      final className = course.name.trim();
      final displayName = code.isNotEmpty ? '$code $className' : className;

      // Process each timestamp
      for (var timestamp in course.timestamps) {
        // Parse as UTC and convert to Hong Kong time
        final startDateTimeUtc = DateTime.fromMillisecondsSinceEpoch(
          timestamp.start.toInt(),
          isUtc: true,
        );
        final endDateTimeUtc = DateTime.fromMillisecondsSinceEpoch(
          timestamp.end.toInt(),
          isUtc: true,
        );
        final startDateTime = startDateTimeUtc.add(const Duration(hours: 8));
        final endDateTime = endDateTimeUtc.add(const Duration(hours: 8));

        // Apply tab filter
        final now = currentDateTimeHK;
        if (selectedTab == 'Upcoming' && endDateTime.isBefore(now)) continue;
        if (selectedTab == 'Past' && endDateTime.isAfter(now)) continue;

        // Determine status
        String status = 'Scheduled';
        if (course.isDeleted == true) {
          status = 'Canceled';
        } else if (endDateTime.isBefore(now)) {
          status = 'Completed';
        }

        // Apply status filter
        if (selectedStatus != null && status != selectedStatus) continue;

        final school = schoolsMap[course.schoolId];
        final tutor = tutorsMap[course.tutorId];

        classList.add(
          ClassListItem(
            courseId: course.id ?? '',
            className: displayName,
            schoolName: school?.name ?? 'Unknown School',
            tutorName: tutor?.name ?? 'Unknown Tutor',
            date: DateFormat('dd/MM/yyyy').format(startDateTime),
            time: '${_formatTime(startDateTime)} - ${_formatTime(endDateTime)}',
            room: course.room,
            status: status,
            startDateTime: startDateTime,
            overview: course.overview,
          ),
        );
      }
    }

    // Sort by tab
    if (selectedTab == 'Upcoming') {
      classList.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    } else {
      classList.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
    }

    return classList;
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
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
                  const Text(
                    'Class',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
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
              _buildFiltersSection(),
              const SizedBox(height: 24),

              // Content
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading classes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
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

  Widget _buildFiltersSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dropdownWidth = 180.0;
        const spacing = 16.0;
        const buttonWidth = 140.0;

        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _buildCourseDropdown(dropdownWidth),
                    _buildSchoolDropdown(dropdownWidth),
                    _buildTutorDropdown(dropdownWidth),
                    _buildStatusDropdown(dropdownWidth),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: buttonWidth,
                    child: CustomButton(
                      text: 'New Class',
                      onPressed: () => context.push('/class/create'),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildCourseDropdown(dropdownWidth),
                  _buildSchoolDropdown(dropdownWidth),
                  _buildTutorDropdown(dropdownWidth),
                  _buildStatusDropdown(dropdownWidth),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: buttonWidth,
                    child: CustomButton(
                      text: 'New Class',
                      onPressed: () => context.push('/class/create'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCourseDropdown(double width) {
    final validIds = courseOptions.map((c) => c.id).toSet();
    final currentValue =
        (selectedCourseId != null && validIds.contains(selectedCourseId))
            ? selectedCourseId
            : null;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: _buildDropdownTheme(
            child: DropdownButton<String?>(
              value: currentValue,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              hint: const Text('All Classes', style: TextStyle(fontSize: 14)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Classes'),
                ),
                ...courseOptions.map(
                  (course) => DropdownMenuItem<String?>(
                    value: course.id,
                    child: Text(
                      course.name,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => selectedCourseId = value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolDropdown(double width) {
    const createNewValue = '__create_new__';
    final validIds = schoolOptions.map((s) => s.id).toSet();
    final currentValue =
        (selectedSchoolId != null && validIds.contains(selectedSchoolId))
            ? selectedSchoolId
            : null;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: _buildDropdownTheme(
            child: DropdownButton<String?>(
              value: currentValue,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              hint: const Text('All Schools', style: TextStyle(fontSize: 14)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Schools'),
                ),
                DropdownMenuItem<String?>(
                  value: createNewValue,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create New School',
                          style: TextStyle(fontSize: 14, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                ...schoolOptions.map(
                  (school) => DropdownMenuItem<String?>(
                    value: school.id,
                    child: Text(
                      school.name,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == createNewValue) {
                  _showCreateSchoolDialog();
                  return;
                }
                setState(() => selectedSchoolId = value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorDropdown(double width) {
    final validIds = tutorOptions.map((t) => t.id).toSet();
    final currentValue =
        (selectedTutorId != null && validIds.contains(selectedTutorId))
            ? selectedTutorId
            : null;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: _buildDropdownTheme(
            child: DropdownButton<String?>(
              value: currentValue,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              hint: const Text('All Tutors', style: TextStyle(fontSize: 14)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Tutors'),
                ),
                ...tutorOptions.map(
                  (tutor) => DropdownMenuItem<String?>(
                    value: tutor.id,
                    child: Text(
                      tutor.name,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => selectedTutorId = value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(double width) {
    const validStatuses = {'Scheduled', 'Completed', 'Canceled'};
    final currentValue =
        (selectedStatus != null && validStatuses.contains(selectedStatus))
            ? selectedStatus
            : null;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: _buildDropdownTheme(
            child: DropdownButton<String?>(
              value: currentValue,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              hint: const Text('All Status', style: TextStyle(fontSize: 14)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Status'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Scheduled',
                  child: Text('Scheduled'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Canceled',
                  child: Text('Canceled'),
                ),
              ],
              onChanged: (value) => setState(() => selectedStatus = value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton(String text, bool isListView) {
    final isActive = isListView;
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
    final isActive = selectedTab == text;
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
              const Text(
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildHeaderCell('Class Name')),
                Expanded(flex: 3, child: _buildHeaderCell('School')),
                Expanded(flex: 1, child: _buildHeaderCell('Tutor')),
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
    return InkWell(
      onTap: () => _showClassDetails(classItem),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                classItem.className,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                classItem.schoolName,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                classItem.tutorName,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                classItem.date,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                classItem.time,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                classItem.room,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(classItem.status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  final String room;
  final String status;
  final DateTime startDateTime;
  final String overview;

  ClassListItem({
    required this.courseId,
    required this.className,
    required this.schoolName,
    required this.tutorName,
    required this.date,
    required this.time,
    required this.room,
    required this.status,
    required this.startDateTime,
    required this.overview,
  });
}

// Create School Dialog
class CreateSchoolDialog extends StatefulWidget {
  final Function(SchoolRes) onSchoolCreated;

  const CreateSchoolDialog({
    Key? key,
    required this.onSchoolCreated,
  }) : super(key: key);

  @override
  State<CreateSchoolDialog> createState() => _CreateSchoolDialogState();
}

class _CreateSchoolDialogState extends State<CreateSchoolDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = CreateSchoolReq(
        _nameController.text.trim(),
        GpsLocation(
          double.tryParse(_latitudeController.text) ?? 0.0,
          double.tryParse(_longitudeController.text) ?? 0.0,
        ),
      );

      final newSchool = await _schoolApi.createSchool(request);
      widget.onSchoolCreated(newSchool);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create New School',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // School Name
              const Text(
                'School Name *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter school name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter school name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GPS Coordinates
              const Text(
                'GPS Coordinates (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: InputDecoration(
                        hintText: 'Latitude',
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: InputDecoration(
                        hintText: 'Longitude',
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    height: 48,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createSchool,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create School',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}