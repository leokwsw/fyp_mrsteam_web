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
import '../widgets/class_details_dialog.dart';

class ClassCalendarScreen extends StatefulWidget {
  const ClassCalendarScreen({Key? key}) : super(key: key);

  @override
  State<ClassCalendarScreen> createState() => _ClassCalendarScreenState();
}

class _ClassCalendarScreenState extends State<ClassCalendarScreen> {
  final ApiProviderCourse _courseApi = getIt<ApiProviderCourse>();
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();

  late DateTime selectedMonth;
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
    selectedMonth = DateTime(
      currentDateTimeHK.year,
      currentDateTimeHK.month,
      1,
    );

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

      // Build lookup maps
      schoolsMap.clear();
      tutorsMap.clear();

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

  // Get events grouped by day for the selected month
  Map<int, List<CalendarClass>> get filteredClassEvents {
    Map<int, List<CalendarClass>> eventsMap = {};

    for (var course in allCourses) {
      // Apply filters
      if (selectedCourseId != null && course.id != selectedCourseId) {
        continue;
      }
      if (selectedSchoolId != null && course.schoolId != selectedSchoolId) {
        continue;
      }
      if (selectedTutorId != null && course.tutorId != selectedTutorId) {
        continue;
      }

      // Process each timestamp
      for (var timestamp in course.timestamps) {
        // Parse as UTC and convert to Hong Kong time for consistent comparison
        final startDateTimeUtc =
            DateTime.fromMillisecondsSinceEpoch(timestamp.start.toInt(), isUtc: true);
        final endDateTimeUtc =
            DateTime.fromMillisecondsSinceEpoch(timestamp.end.toInt(), isUtc: true);
        final startDateTime = startDateTimeUtc.add(const Duration(hours: 8));
        final endDateTime = endDateTimeUtc.add(const Duration(hours: 8));

        // Check if this timestamp is in the selected month
        if (startDateTime.year == selectedMonth.year &&
            startDateTime.month == selectedMonth.month) {
          // Apply tab filter - use endDateTime for "Upcoming" to include ongoing classes
          final now = currentDateTimeHK;
          if (selectedTab == 'Upcoming' && endDateTime.isBefore(now)) continue;
          if (selectedTab == 'Past' && endDateTime.isAfter(now)) continue;

          // Determine status based on end time
          String status = 'Scheduled';
          if (course.isDeleted == true) {
            status = 'Canceled';
          } else if (endDateTime.isBefore(now)) {
            status = 'Completed';
          }

          // Apply status filter
          if (selectedStatus != null && status != selectedStatus) {
            continue;
          }

          final school = schoolsMap[course.schoolId];
          final tutor = tutorsMap[course.tutorId];

          final code = course.courseCode.trim();
          final displayName = code.isNotEmpty ? '$code ${course.name.trim()}' : course.name.trim();

          final calendarClass = CalendarClass(
            courseId: course.id ?? '',
            schoolName: school?.name ?? 'Unknown School',
            time: '${_formatTime(startDateTime)} - ${_formatTime(endDateTime)}',
            classCode: displayName,
            color: status == 'Canceled' ? Colors.red : Colors.blue,
            tutor: tutor?.name ?? 'Unknown Tutor',
            status: status,
            room: course.room,
            notes: course.overview,
            startAt: startDateTime,
          );

          final day = startDateTime.day;
          eventsMap.putIfAbsent(day, () => []);
          eventsMap[day]!.add(calendarClass);
        }
      }
    }

    for (final list in eventsMap.values) {
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
    }

    return eventsMap;
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      currentDateTimeHK = _getHongKongTime();
      selectedMonth = DateTime(
        currentDateTimeHK.year,
        currentDateTimeHK.month,
        1,
      );
    });
  }

  void _showEventDetails(CalendarClass event) {
    showDialog(
      context: context,
      builder: (context) => ClassDetailsDialog(
        courseId: event.courseId,
        className: event.classCode,
        schoolName: event.schoolName,
        time: event.time,
        tutorName: event.tutor,
        room: event.room,
        status: event.status,
        overview: event.notes,
      ),
    );
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
                  _buildViewButton('Calendar View', true),
                  const SizedBox(width: 16),
                  _buildViewButton('List View', false),
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

              // Month Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                        tooltip: 'Previous Month',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                        tooltip: 'Next Month',
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _goToToday,
                        icon: const Icon(Icons.today, size: 18),
                        label: const Text('Today'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadData,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filters and New Class Button - Responsive Layout
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
                        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else
                _buildCalendar(),
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
              SizedBox(
                width: buttonWidth,
                child: CustomButton(
                  text: 'New Class',
                  onPressed: () => context.push('/class/create'),
                ),
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
              SizedBox(
                width: buttonWidth,
                child: CustomButton(
                  text: 'New Class',
                  onPressed: () => context.push('/class/create'),
                ),
              ),
            ],
          );
        }
      },
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
              onChanged: (value) => setState(() => selectedSchoolId = value),
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

  Widget _buildViewButton(String text, bool isCalendar) {
    bool isActive = isCalendar;
    return GestureDetector(
      onTap: () {
        if (!isCalendar) {
          context.go('/class/list');
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

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;
    final prevMonthLastDay = DateTime(selectedMonth.year, selectedMonth.month, 0).day;
    final prevMonthDaysToShow = startWeekday;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                _buildDayHeader('SUN'),
                _buildDayHeader('MON'),
                _buildDayHeader('TUE'),
                _buildDayHeader('WED'),
                _buildDayHeader('THU'),
                _buildDayHeader('FRI'),
                _buildDayHeader('SAT'),
              ],
            ),
          ),
          _buildCalendarGrid(daysInMonth, startWeekday, prevMonthLastDay, prevMonthDaysToShow),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String day) {
    return Expanded(
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(
    int daysInMonth,
    int startWeekday,
    int prevMonthLastDay,
    int prevMonthDaysToShow,
  ) {
    List<Widget> weeks = [];
    int currentDay = 1;
    int nextMonthDay = 1;
    int totalCells = daysInMonth + startWeekday;
    int numWeeks = (totalCells / 7).ceil();

    for (int week = 0; week < numWeeks; week++) {
      List<Widget> days = [];

      for (int weekday = 0; weekday < 7; weekday++) {
        int cellIndex = week * 7 + weekday;

        if (cellIndex < startWeekday) {
          int prevDay = prevMonthLastDay - prevMonthDaysToShow + cellIndex + 1;
          days.add(_buildCalendarCell(prevDay, true, []));
        } else if (currentDay <= daysInMonth) {
          bool isToday = selectedMonth.year == currentDateTimeHK.year &&
              selectedMonth.month == currentDateTimeHK.month &&
              currentDay == currentDateTimeHK.day;

          List<CalendarClass> events = filteredClassEvents[currentDay] ?? [];
          days.add(_buildCalendarCell(currentDay, false, events, isToday: isToday));
          currentDay++;
        } else {
          days.add(_buildCalendarCell(nextMonthDay, true, []));
          nextMonthDay++;
        }
      }

      weeks.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: days));
    }

    return Column(children: weeks);
  }

  Widget _buildCalendarCell(
    int day,
    bool isOtherMonth,
    List<CalendarClass> events, {
    bool isToday = false,
  }) {
    return Expanded(
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFD6E4F5) : Colors.white,
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: isToday
                    ? BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
                    : null,
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? Colors.white
                          : isOtherMonth
                              ? AppColors.textSecondary.withOpacity(0.4)
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            if (events.isNotEmpty)
              Positioned(
                top: 36,
                left: 4,
                right: 4,
                bottom: 4,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: events.map((event) => _buildEventCard(event)).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(CalendarClass event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        height: 46,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: event.status == 'Canceled'
              ? const Color(0xFFB71C1C)
              : const Color.fromARGB(255, 37, 120, 228),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              event.classCode,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              event.time,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}

class CalendarClass {
  final String courseId;
  final String schoolName;
  final String time;
  final String classCode;
  final Color color;
  final String tutor;
  final String status;
  final String room;
  final String notes;
  final DateTime startAt;

  CalendarClass({
    required this.courseId,
    required this.schoolName,
    required this.time,
    required this.classCode,
    required this.color,
    required this.tutor,
    required this.status,
    required this.room,
    required this.notes,
    required this.startAt,
  });
}