import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:excel/excel.dart' show Excel, TextCellValue;
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
import '../data/model/request/req_school.dart';
import '../data/model/response/res_attendance.dart';
import '../data/model/response/res_course.dart';
import '../data/model/response/res_school.dart';
import '../data/model/response/res_user.dart';

enum ExportFormat { csv, excel }

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

  Theme _buildDropdownTheme({required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white, // dropdown popup background
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent, // remove default purple press highlight
        hoverColor: const Color(0xFFF5F5F5), // subtle hover
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
      tutorsMap.clear();
      coursesMap.clear();
      schoolsMap.clear();

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

      // Reset selected values if they don't exist in the loaded options
      if (selectedTutorId != null && !tutorsMap.containsKey(selectedTutorId)) {
        selectedTutorId = null;
      }
      if (selectedCourseId != null && !coursesMap.containsKey(selectedCourseId)) {
        selectedCourseId = null;
      }
      if (selectedSchoolId != null && !schoolsMap.containsKey(selectedSchoolId)) {
        selectedSchoolId = null;
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

  Future<ExportFormat?> _showExportFormatDialog() async {
    return showDialog<ExportFormat>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('CSV'),
              onTap: () => Navigator.pop(context, ExportFormat.csv),
            ),
            ListTile(
              leading: const Icon(Icons.grid_on_outlined),
              title: const Text('Excel (.xlsx)'),
              onTap: () => Navigator.pop(context, ExportFormat.excel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportRecords(ExportFormat format) async {
    setState(() => isExporting = true);

    try {
      final records = _getFilteredAttendances();
      if (records.isEmpty) {
        throw Exception('No attendance records to export.');
      }

      final rows = _buildExportRows(records);
      final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final baseName = 'attendance_records_$now';

      if (format == ExportFormat.csv) {
        final csvText = _toCsv(rows);
        // BOM for better Excel UTF-8 compatibility
        final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csvText'));
        _downloadBytesFile(
          bytes: bytes,
          fileName: '$baseName.csv',
          mimeType: 'text/csv;charset=utf-8',
        );
      } else {
        final bytes = _toXlsx(rows);
        _downloadBytesFile(
          bytes: bytes,
          fileName: '$baseName.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export completed: ${format == ExportFormat.csv ? '$baseName.csv' : '$baseName.xlsx'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  List<AttendanceRes> _getFilteredAttendances() {
    final now = DateTime.now();

    final filteredAttendances = attendances.where((attendance) {
      // Exclude future classes
      try {
        final scheduledStart = _epochMsToLocal(attendance.timestamp.start);
        if (scheduledStart.isAfter(now)) {
          return false;
        }
      } catch (_) {}

      // Status filter
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
        final courseCode = (course?.courseCode ?? '').toLowerCase();
        final schoolName = school?.name.toLowerCase() ?? '';

        if (!tutorName.contains(searchQuery) &&
            !courseName.contains(searchQuery) &&
            !courseCode.contains(searchQuery) &&
            !schoolName.contains(searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Most recent first
    filteredAttendances.sort((a, b) {
      final aStart = a.timestamp.start.toInt();
      final bStart = b.timestamp.start.toInt();
      return bStart.compareTo(aStart);
    });

    return filteredAttendances;
  }

  List<List<String>> _buildExportRows(List<AttendanceRes> records) {
    final rows = <List<String>>[
      ['Tutor', 'Class', 'School', 'Scheduled Time', 'Check-in Time', 'Status'],
    ];

    for (final attendance in records) {
      final tutor = tutorsMap[attendance.tutorId];
      final course = coursesMap[attendance.courseId];
      final school = schoolsMap[attendance.schoolId];
      final status = _getStatusFromAttendance(attendance);

      rows.add([
        tutor?.name ?? attendance.tutorId,
        _formatClassDisplayName(course, attendance.courseId),
        school?.name ?? attendance.schoolId,
        _formatTimestamp(attendance.timestamp).replaceAll('\n', ' '),
        _formatCheckInTime(attendance.checkInTime).replaceAll('\n', ' '),
        status,
      ]);
    }

    return rows;
  }

  String _toCsv(List<List<String>> rows) {
    String esc(String v) {
      final needQuote =
          v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r');
      final safe = v.replaceAll('"', '""');
      return needQuote ? '"$safe"' : safe;
    }

    return rows.map((row) => row.map(esc).join(',')).join('\n');
  }

  Uint8List _toXlsx(List<List<String>> rows) {
    final excel = Excel.createExcel();

    // Remove default sheet if exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final sheet = excel['Attendance'];
    for (final row in rows) {
      sheet.appendRow(row.map((v) => TextCellValue(v)).toList());
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? <int>[]);
  }

  void _downloadBytesFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..style.display = 'none'
      ..download = fileName;

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  void _showCreateSchoolDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateSchoolDialog(
        onSchoolCreated: (newSchool) {
          setState(() {
            schoolOptions.add(newSchool);
            if (newSchool.id != null) {
              schoolsMap[newSchool.id!] = newSchool;
            }
            selectedSchoolId = newSchool.id;
          });
          _loadAttendances();
        },
      ),
    );
  }

  String _getStatusFromAttendance(AttendanceRes attendance) {
    if (!attendance.checked) return 'Absent';

    final checkIn = _isoToLocal(attendance.checkInTime);
    if (checkIn == null) return 'Present';

    try {
      final scheduledStart = _epochMsToLocal(attendance.timestamp.start);

      // Late threshold = 5 minutes
      if (checkIn.isAfter(scheduledStart.add(const Duration(minutes: 5)))) {
        return 'Late';
      }
    } catch (_) {}

    return 'Present';
  }

  StatusType _getStatusType(String status) {
    switch (status) {
      case 'Present':
        return StatusType.success;
      case 'Absent':
      case 'Late':
        return StatusType.error;
      default:
        return StatusType.success;
    }
  }

  String _formatTimestamp(CourseTimestampRes timestamp) {
    try {
      final start = _epochMsToLocal(timestamp.start);
      final end = _epochMsToLocal(timestamp.end);
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');

      return '${dateFormat.format(start)}\n${timeFormat.format(start)} - ${timeFormat.format(end)}';
    } catch (_) {
      return '-';
    }
  }

  DateTime _epochMsToLocal(num ms) {
    return DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true).toLocal();
  }

  DateTime? _isoToLocal(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatCheckInTime(String? checkInTime) {
    final dt = _isoToLocal(checkInTime);
    if (dt == null) return '-';

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dt)}\n${timeFormat.format(dt)}';
  }

  String _formatClassDisplayName(CourseRes? course, String fallbackId) {
    if (course == null) return fallbackId;

    final code = course.courseCode.trim();
    final name = course.name.trim();

    if (code.isEmpty) return name.isNotEmpty ? name : fallbackId;
    if (name.isEmpty) return code;
    return '$code $name';
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
              const Text(
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
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
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
                          'Error loading attendance',
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
                _buildAttendanceTable(),

              const SizedBox(height: 24),

              // Export Button
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isExporting
                        ? null
                        : () async {
                            final format = await _showExportFormatDialog();
                            if (format != null) {
                              await _exportRecords(format);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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
    final validTutorIds = tutorOptions.map((t) => t.id).toSet();
    final currentValue = (selectedTutorId != null &&
            validTutorIds.contains(selectedTutorId))
        ? selectedTutorId
        : null;

    return SizedBox(
      width: 180,
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
              isExpanded: true,
              hint: const Text('All Tutors', style: TextStyle(fontSize: 14)),
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
              onChanged: (value) {
                setState(() => selectedTutorId = value);
                _loadAttendances();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    final validCourseIds = courseOptions.map((c) => c.id).toSet();
    final currentValue = (selectedCourseId != null &&
            validCourseIds.contains(selectedCourseId))
        ? selectedCourseId
        : null;

    return SizedBox(
      width: 180,
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
              isExpanded: true,
              hint: const Text('All Classes', style: TextStyle(fontSize: 14)),
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
              onChanged: (value) {
                setState(() => selectedCourseId = value);
                _loadAttendances();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    final validSchoolIds = schoolOptions.map((s) => s.id).toSet();
    final currentValue = (selectedSchoolId != null &&
            validSchoolIds.contains(selectedSchoolId))
        ? selectedSchoolId
        : null;

    return SizedBox(
      width: 180,
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
              isExpanded: true,
              hint: const Text('All Schools', style: TextStyle(fontSize: 14)),
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Schools'),
                ),
                DropdownMenuItem<String?>(
                  value: '__create_new__',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create New School',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
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
                if (value == '__create_new__') {
                  _showCreateSchoolDialog();
                } else {
                  setState(() => selectedSchoolId = value);
                  _loadAttendances();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final validStatuses = {'Present', 'Absent', 'Late'};
    final currentValue =
        (selectedStatus != null && validStatuses.contains(selectedStatus))
            ? selectedStatus
            : null;

    return SizedBox(
      width: 180,
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
              isExpanded: true,
              hint: const Text('All Status', style: TextStyle(fontSize: 14)),
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Status'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Present',
                  child: Text('Present'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Absent',
                  child: Text('Absent'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Late',
                  child: Text('Late'),
                ),
              ],
              onChanged: (value) {
                setState(() => selectedStatus = value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    final filteredAttendances = _getFilteredAttendances();

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
              Text(
                'No attendance records found',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
        border:
            Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
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
              _formatClassDisplayName(course, attendance.courseId),
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

// Create School Dialog
class CreateSchoolDialog extends StatefulWidget {
  final Function(SchoolRes) onSchoolCreated;

  const CreateSchoolDialog({Key? key, required this.onSchoolCreated})
      : super(key: key);

  @override
  State<CreateSchoolDialog> createState() => _CreateSchoolDialogState();
}

class _CreateSchoolDialogState extends State<CreateSchoolDialog> {
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  bool isSaving = false;
  String? errorMessage;

  Future<void> _createSchool() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter school name');
      return;
    }

    final lat = double.tryParse(_latController.text.trim());
    final long = double.tryParse(_longController.text.trim());

    if (_latController.text.trim().isNotEmpty || _longController.text.trim().isNotEmpty) {
      if (lat == null || long == null) {
        setState(() => errorMessage = 'Please enter valid GPS coordinates');
        return;
      }
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final request = CreateSchoolReq(
        _nameController.text.trim(),
        GpsLocation(lat ?? 0.0, long ?? 0.0),
      );

      final response = await _schoolApi.createSchool(request);

      if (mounted) {
        widget.onSchoolCreated(response);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School "${response.name}" created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to create school: ${e.toString()}';
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create New School',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // School Name
            Text(
              'School Name *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter school name',
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
            const SizedBox(height: 24),

            // GPS Coordinates
            Text(
              'GPS Location (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Latitude',
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _longController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Longitude',
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'e.g., Hong Kong: 22.3193, 114.1694',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 120,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      side: BorderSide(color: AppColors.inputBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _createSchool,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create',
                            style:
                                TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }
}