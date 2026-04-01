import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_text_field.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_course.dart';
import '../data/api/api_provider_files.dart';
import '../data/api/api_provider_school.dart';
import '../data/api/api_provider_users.dart';
import '../data/model/request/req_course.dart';
import '../data/model/request/req_file.dart';
import '../data/model/request/req_school.dart';
import '../data/model/response/res_school.dart';
import '../data/model/response/res_user.dart';
import '../services/places_search_service.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// 通用表单样式
/// ─────────────────────────────────────────────────────────────────────────
class FormUi {
  static TextStyle labelStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.6),
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
      contentPadding: maxLines > 1
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  static InputDecoration dropdownDecoration({
    required String hintText,
  }) {
    return inputDecoration(hintText: hintText).copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  static Theme wrapDropdownTheme(BuildContext context, Widget child) {
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
}

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final ApiProviderCourse _courseApi = getIt<ApiProviderCourse>();
  final ApiProviderFiles _filesApi = getIt<ApiProviderFiles>();
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();

  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectCodeController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _overviewController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String? selectedSchoolId;
  String? selectedTutorId;
  DateTime? startDateTime;
  DateTime? endDateTime;
  DateTime? recurrenceEndDate;

  // 重複規則
  bool isRecurring = false;
  RecurrenceFrequency? selectedFrequency;
  int recurrenceInterval = 1;
  int? recurrenceOccurrences;

  List<SchoolRes> schools = [];
  List<UserResponse> tutors = [];
  List<CourseFileReq> uploadedFiles = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isUploading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ThemeData _whitePickerThemeAutoPrimary(BuildContext context) {
  final base = Theme.of(context);

  final primary = AppColors.primary;

  final surface = Colors.white;
  final onSurface = Colors.black87;
  final disabled = Colors.grey.shade400;

  final scheme = base.colorScheme.copyWith(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: Colors.grey.shade700,
    tertiary: primary,
  );

  return base.copyWith(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    canvasColor: surface,
    dialogBackgroundColor: surface,

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,

      headerBackgroundColor: surface,
      headerForegroundColor: onSurface,

      weekdayStyle: TextStyle(color: Colors.grey.shade700),

      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabled;
        return onSurface;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.transparent;
      }),

      dayShape: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return CircleBorder(
            side: BorderSide(color: primary, width: 1.6),
          );
        }
        return const CircleBorder();
      }),

      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabled;
        return onSurface;
      }),
      todayBorder: BorderSide(color: primary, width: 1.2),

      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabled;
        if (states.contains(WidgetState.selected)) return Colors.white;
        return onSurface;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return Colors.transparent;
      }),

      dividerColor: Colors.grey.shade200,
      rangeSelectionBackgroundColor: primary.withOpacity(0.12),

      cancelButtonStyle: TextButton.styleFrom(foregroundColor: primary),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: primary),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: surface,
      dialBackgroundColor: Colors.grey.shade100,
      hourMinuteColor: Colors.grey.shade100,
      hourMinuteTextColor: onSurface,
      dayPeriodColor: Colors.grey.shade100,
      dayPeriodTextColor: onSurface,
      dialHandColor: primary,
      dialTextColor: onSurface,
      entryModeIconColor: primary,
      helpTextStyle: TextStyle(color: onSurface),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: primary),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: primary),
    ),
  );
}

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _schoolApi.getSchools(),
        _usersApi.getUsers(role: 'tutor'),
      ]);

      final schoolsRes = futures[0] as SchoolListRes;
      final tutorsRes = futures[1] as dynamic;

      final loadedSchools = schoolsRes.items;
      final loadedTutors = tutorsRes.items as List<UserResponse>;

      if (selectedSchoolId != null &&
          !loadedSchools.any((s) => s.id == selectedSchoolId)) {
        selectedSchoolId = null;
      }
      if (selectedTutorId != null &&
          !loadedTutors.any((t) => t.id == selectedTutorId)) {
        selectedTutorId = null;
      }

      setState(() {
        schools = loadedSchools;
        tutors = loadedTutors;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  /// Build Content-Disposition headers for UTF-8/Chinese filename support (RFC 5987)
  Map<String, List<String>> _utf8FilenameHeaders(String filename) {
    final ext = path.extension(filename);
    final fallback = 'file${ext.isEmpty ? '' : ext}';
    final encoded = Uri.encodeComponent(filename);
    return {
      'Content-Disposition': [
        'form-data; name="file"; filename="$fallback"; filename*=UTF-8\'\'$encoded',
      ],
    };
  }

  /// 上傳文件
  Future<void> _uploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'ppt',
          'pptx',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'png',
          'jpg',
          'jpeg',
        ],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => isUploading = true);

      for (var file in result.files) {
        try {
          MultipartFile multipartFile;
          final utf8Headers = _utf8FilenameHeaders(file.name);

          if (file.bytes != null) {
            multipartFile = MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
              headers: utf8Headers,
            );
          } else if (file.path != null) {
            multipartFile = await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
              headers: utf8Headers,
            );
          } else {
            continue;
          }

          final request = UploadFileReq(multipartFile);
          final response = await _filesApi.uploadFile(request);

          if (!mounted) return;
          setState(() {
            uploadedFiles.add(
              CourseFileReq(
                originalName: response.file.originalName,
                filename: response.file.originalName,
                path: response.file.path,
                url: response.file.url,
                size: response.file.size.toInt(),
                mimetype: response.file.mimetype,
              ),
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${file.name} uploaded successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to upload ${file.name}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) setState(() => isUploading = false);
    } catch (e) {
      if (mounted) setState(() => isUploading = false);
      _showError('File upload failed: ${e.toString()}');
    }
  }

  void _removeFile(int index) {
    setState(() {
      uploadedFiles.removeAt(index);
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String mimetype) {
    if (mimetype.contains('pdf')) return Icons.picture_as_pdf;
    if (mimetype.contains('word') || mimetype.contains('document')) {
      return Icons.description;
    }
    if (mimetype.contains('powerpoint') || mimetype.contains('presentation')) {
      return Icons.slideshow;
    }
    if (mimetype.contains('excel') || mimetype.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    if (mimetype.contains('image')) return Icons.image;
    return Icons.insert_drive_file;
  }

  List<CourseTimestampReq> _generateTimestamps() {
    if (!isRecurring || startDateTime == null || endDateTime == null) {
      return [
        CourseTimestampReq(
          startDateTime!.millisecondsSinceEpoch,
          endDateTime!.millisecondsSinceEpoch,
        ),
      ];
    }

    if (selectedFrequency == null) {
      _showError('Please select recurrence frequency');
      return [];
    }

    if (recurrenceEndDate == null && recurrenceOccurrences == null) {
      _showError('Please set an end date or number of occurrences');
      return [];
    }

    return generateRecurrenceTimestamps(
      startDateTime: startDateTime!,
      endDateTime: endDateTime!,
      frequency: selectedFrequency!,
      interval: recurrenceInterval,
      endDate: recurrenceEndDate,
      occurrenceCount: recurrenceOccurrences,
    );
  }

  int _getPreviewSessionCount() {
    if (startDateTime == null ||
        endDateTime == null ||
        selectedFrequency == null) {
      return 0;
    }
    if (recurrenceEndDate == null && recurrenceOccurrences == null) {
      return 0;
    }
    try {
      final previewTimestamps = generateRecurrenceTimestamps(
        startDateTime: startDateTime!,
        endDateTime: endDateTime!,
        frequency: selectedFrequency!,
        interval: recurrenceInterval,
        endDate: recurrenceEndDate,
        occurrenceCount: recurrenceOccurrences,
      );
      return previewTimestamps.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _showOccurrencesDialog() async {
    final controller = TextEditingController(
      text: recurrenceOccurrences?.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Number of Occurrences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How many class sessions should be created?',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: FormUi.inputDecoration(hintText: 'e.g., 4'),
                onSubmitted: (value) {
                  final count = int.tryParse(value);
                  if (count != null && count > 0 && count <= 100) {
                    Navigator.of(dialogContext).pop(count);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum: 100 sessions',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final count = int.tryParse(controller.text);
                if (count != null && count > 0 && count <= 100) {
                  Navigator.of(dialogContext).pop(count);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        recurrenceOccurrences = result;
        recurrenceEndDate = null;
      });
    }
  }

  Future<void> _saveClass() async {
    if (_classNameController.text.trim().isEmpty) {
      _showError('Please enter class name');
      return;
    }
    if (_subjectCodeController.text.trim().isEmpty) {
      _showError('Please enter subject code (max 4 characters)');
      return;
    }
    if (_subjectCodeController.text.trim().length > 4) {
      _showError('Subject code must be at most 4 characters');
      return;
    }
    if (_overviewController.text.trim().isEmpty) {
      _showError('Please enter overview');
      return;
    }
    if (selectedSchoolId == null) {
      _showError('Please select a school');
      return;
    }
    if (selectedTutorId == null) {
      _showError('Please select a tutor');
      return;
    }
    if (startDateTime == null || endDateTime == null) {
      _showError('Please set start and end time');
      return;
    }
    if (endDateTime!.isBefore(startDateTime!)) {
      _showError('End time must be after start time');
      return;
    }

    if (isRecurring) {
      if (selectedFrequency == null) {
        _showError('Please select a recurrence frequency');
        return;
      }
      if (recurrenceEndDate == null && recurrenceOccurrences == null) {
        _showError('Please set an end date or number of occurrences');
        return;
      }
    }

    final timestamps = _generateTimestamps();
    if (timestamps.isEmpty) return;

    setState(() => isSaving = true);

    try {
      final request = CreateCourseReq(
        _classNameController.text.trim(),
        _overviewController.text.trim(),
        _roomController.text.trim(),
        uploadedFiles,
        selectedSchoolId!,
        selectedTutorId!,
        timestamps,
        _subjectCodeController.text.trim().toUpperCase(),
      );

      await _courseApi.createCourse(request);

      if (mounted) {
        final sessionText = timestamps.length > 1
            ? ' with ${timestamps.length} sessions'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class created successfully$sessionText'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/class');
      }
    } catch (e) {
      _showError('Failed to create class: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showCreateSchoolDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateSchoolDialog(
        onSchoolCreated: (newSchool) {
          setState(() {
            schools.add(newSchool);
            selectedSchoolId = newSchool.id;
          });
        },
      ),
    );
  }

  /// 统一日期+时间选择流程（白底 + 自动主色）
  Future<DateTime?> _pickDateTime({
    DateTime? initialValue,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final now = DateTime.now();
    final initialDate = initialValue == null
        ? now
        : (initialValue.isBefore(firstDate)
            ? firstDate
            : (initialValue.isAfter(lastDate) ? lastDate : initialValue));

    final pickerTheme = _whitePickerThemeAutoPrimary(context);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: pickerTheme,
          child: child!,
        );
      },
    );

    if (pickedDate == null) return null;

    final initialTime = initialValue != null
        ? TimeOfDay(hour: initialValue.hour, minute: initialValue.minute)
        : TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: pickerTheme,
          child: child!,
        );
      },
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/class/create'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/class/create'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading data'),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/class/create'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Create New Class',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 40),

                  CustomTextField(
                    label: 'Class Name *',
                    placeholder: 'e.g., Mathematics Level 1',
                    controller: _classNameController,
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Subject Code *',
                    placeholder: 'e.g., MATH',
                    controller: _subjectCodeController,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 24),

                  _buildDateTimeField(
                    label: 'Start Date and Time *',
                    controller: _startTimeController,
                    isStartField: true,
                  ),
                  const SizedBox(height: 24),

                  _buildDateTimeField(
                    label: 'End Date and Time *',
                    controller: _endTimeController,
                    isStartField: false,
                  ),
                  const SizedBox(height: 24),

                  _buildSchoolDropdown(),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Room',
                    placeholder: 'e.g., Room 301',
                    controller: _roomController,
                  ),
                  const SizedBox(height: 24),

                  _buildTutorDropdown(),
                  const SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview / Notification Content *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _overviewController,
                        maxLines: 4,
                        decoration: FormUi.inputDecoration(
                          hintText:
                              'Class description and notification content for tutors',
                          maxLines: 4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildRecurringSection(),
                  const SizedBox(height: 24),

                  _buildUploadSection(),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () => context.go('/class'),
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
                          onPressed: isSaving ? null : _saveClass,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: FormUi.labelStyle),
          const SizedBox(height: 8),
        ],
        FormUi.wrapDropdownTheme(
          context,
          DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(8),
            icon: Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondary),
            decoration: FormUi.dropdownDecoration(hintText: hint),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required TextEditingController controller,
    required bool isStartField,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FormUi.labelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: FormUi.inputDecoration(
            hintText: 'YYYY/MM/DD HH:MM',
            suffixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary),
          ),
          onTap: () async {
            final now = DateTime.now();
            final picked = await _pickDateTime(
              initialValue: isStartField ? startDateTime : endDateTime,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: now.add(const Duration(days: 365)),
            );

            if (picked == null) return;

            if (picked.isBefore(now)) {
              _showError(
                isStartField
                    ? 'Start time must be later than current time'
                    : 'End time must be later than current time',
              );
              return;
            }

            if (!isStartField &&
                startDateTime != null &&
                picked.isBefore(startDateTime!)) {
              _showError('End time must be later than start time');
              return;
            }

            setState(() {
              if (isStartField) {
                startDateTime = picked;
              } else {
                endDateTime = picked;
              }
              controller.text = _formatDateTime(picked);
            });
          },
        ),
      ],
    );
  }

  Widget _buildSchoolDropdown() {
    const createNewValue = '__create_new__';
    final validIds = schools.map((s) => s.id).toSet();
    final currentValue =
        selectedSchoolId != null && validIds.contains(selectedSchoolId)
            ? selectedSchoolId
            : null;

    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: createNewValue,
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Create New School',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const DropdownMenuItem<String>(
        enabled: false,
        value: '__divider__',
        child: Divider(height: 1),
      ),
      ...schools.map(
        (school) => DropdownMenuItem<String>(
          value: school.id,
          child: Text(school.name),
        ),
      ),
    ];

    return _buildDropdownField<String>(
      label: 'School *',
      value: currentValue,
      hint: 'Select School',
      items: items,
      onChanged: (value) {
        if (value == createNewValue) {
          _showCreateSchoolDialog();
          return;
        }
        if (value == '__divider__') return;
        setState(() => selectedSchoolId = value);
      },
    );
  }

  Widget _buildTutorDropdown() {
    final validIds = tutors.map((t) => t.id).toSet();
    final currentValue =
        selectedTutorId != null && validIds.contains(selectedTutorId)
            ? selectedTutorId
            : null;

    return _buildDropdownField<String>(
      label: 'Tutor *',
      value: currentValue,
      hint: 'Select Tutor',
      items: tutors
          .map(
            (tutor) => DropdownMenuItem<String>(
              value: tutor.id,
              child: Text(tutor.name),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() => selectedTutorId = value);
      },
    );
  }

  Widget _buildRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: isRecurring,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  isRecurring = value ?? false;
                  if (!isRecurring) {
                    selectedFrequency = null;
                    recurrenceInterval = 1;
                    recurrenceOccurrences = null;
                    recurrenceEndDate = null;
                  }
                });
              },
            ),
            const Text(
              'Recurring Class',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Create multiple class sessions at regular intervals (weekly, bi-weekly, or monthly)',
              child: Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
        if (isRecurring) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Repeat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField<RecurrenceFrequency>(
                        label: '',
                        value: selectedFrequency,
                        hint: 'Select frequency',
                        items: const [
                          DropdownMenuItem(
                            value: RecurrenceFrequency.weekly,
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: RecurrenceFrequency.biweekly,
                            child: Text('Bi-weekly'),
                          ),
                          DropdownMenuItem(
                            value: RecurrenceFrequency.monthly,
                            child: Text('Monthly'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedFrequency = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('every', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: FormUi.inputDecoration(hintText: '1'),
                        onChanged: (value) {
                          setState(() {
                            recurrenceInterval = int.tryParse(value) ?? 1;
                            if (recurrenceInterval < 1) recurrenceInterval = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_getIntervalUnitLabel(),
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('End Condition',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  'Choose one: end by date or by number of occurrences',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final pickerTheme = _whitePickerThemeAutoPrimary(context);
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                recurrenceEndDate ?? startDateTime ?? DateTime.now(),
                            firstDate: startDateTime ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            builder: (context, child) {
                              return Theme(data: pickerTheme, child: child!);
                            },
                          );
                          if (date != null) {
                            setState(() {
                              recurrenceEndDate = date;
                              recurrenceOccurrences = null;
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: recurrenceEndDate != null
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.inputBackground,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: recurrenceEndDate != null
                                  ? AppColors.primary.withOpacity(0.3)
                                  : AppColors.inputBorder,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              recurrenceEndDate != null
                                  ? Icons.calendar_today
                                  : Icons.calendar_today_outlined,
                              size: 18,
                              color: recurrenceEndDate != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recurrenceEndDate != null
                                    ? 'Until ${recurrenceEndDate!.year}/${recurrenceEndDate!.month.toString().padLeft(2, '0')}/${recurrenceEndDate!.day.toString().padLeft(2, '0')}'
                                    : 'End Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: recurrenceEndDate != null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (recurrenceEndDate != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => recurrenceEndDate = null);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.close, size: 16, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: _showOccurrencesDialog,
                        style: TextButton.styleFrom(
                          backgroundColor: recurrenceOccurrences != null
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.inputBackground,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: recurrenceOccurrences != null
                                  ? AppColors.primary.withOpacity(0.3)
                                  : AppColors.inputBorder,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.repeat_one,
                              size: 18,
                              color: recurrenceOccurrences != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recurrenceOccurrences != null
                                    ? '$recurrenceOccurrences times'
                                    : 'Occurrences',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: recurrenceOccurrences != null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (recurrenceOccurrences != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => recurrenceOccurrences = null);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.close, size: 16, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (recurrenceEndDate != null || recurrenceOccurrences != null) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final sessionCount = _getPreviewSessionCount();
                      final hasRequiredFields = startDateTime != null &&
                          endDateTime != null &&
                          selectedFrequency != null;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasRequiredFields && sessionCount > 0
                              ? AppColors.primary.withOpacity(0.05)
                              : Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasRequiredFields && sessionCount > 0
                                ? AppColors.primary.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasRequiredFields && sessionCount > 0
                                  ? Icons.event_repeat
                                  : Icons.warning_amber_rounded,
                              size: 20,
                              color: hasRequiredFields && sessionCount > 0
                                  ? AppColors.primary
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasRequiredFields && sessionCount > 0
                                        ? 'Will generate $sessionCount class session${sessionCount != 1 ? 's' : ''}'
                                        : 'Set start/end time and frequency to preview sessions',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hasRequiredFields && sessionCount > 0
                                          ? AppColors.primary
                                          : Colors.orange[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (hasRequiredFields && sessionCount > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _getRecurrenceSummary(sessionCount),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getIntervalUnitLabel() {
    switch (selectedFrequency) {
      case RecurrenceFrequency.weekly:
        return recurrenceInterval == 1 ? 'week' : 'weeks';
      case RecurrenceFrequency.biweekly:
        return recurrenceInterval == 1 ? 'cycle' : 'cycles';
      case RecurrenceFrequency.monthly:
        return recurrenceInterval == 1 ? 'month' : 'months';
      default:
        return 'interval(s)';
    }
  }

  String _getRecurrenceSummary(int sessionCount) {
    if (startDateTime == null || selectedFrequency == null) return '';

    final dayName = _getDayName(startDateTime!.weekday);
    final timeStr =
        '${startDateTime!.hour.toString().padLeft(2, '0')}:${startDateTime!.minute.toString().padLeft(2, '0')}';

    String freqStr;
    switch (selectedFrequency!) {
      case RecurrenceFrequency.weekly:
        freqStr = recurrenceInterval == 1
            ? 'Every $dayName'
            : 'Every $recurrenceInterval weeks on $dayName';
        break;
      case RecurrenceFrequency.biweekly:
        freqStr = 'Every other $dayName';
        break;
      case RecurrenceFrequency.monthly:
        final dayOfMonth = startDateTime!.day;
        freqStr = recurrenceInterval == 1
            ? 'Monthly on the ${_getOrdinal(dayOfMonth)}'
            : 'Every $recurrenceInterval months on the ${_getOrdinal(dayOfMonth)}';
        break;
    }

    return '$freqStr at $timeStr';
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getOrdinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Upload Teaching Materials',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'PDF, PPT, DOC, XLS, Images (Max 10MB each)',
              child: Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: isUploading ? AppColors.primary : AppColors.inputBorder,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.inputBackground,
          ),
          child: isUploading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Uploading files...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : uploadedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'Drag and drop files here or click to upload',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PPT, PDF, DOC, XLS, PNG, JPG',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _uploadFiles,
                            icon: const Icon(Icons.folder_open, size: 18),
                            label: const Text('Browse Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: uploadedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = uploadedFiles[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getFileIcon(file.mimetype),
                                          color: AppColors.primary,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                file.originalName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                _formatFileSize(file.size),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _removeFile(index),
                                          tooltip: 'Remove',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _uploadFiles,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add More Files'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => uploadedFiles.clear()),
                                  icon: const Icon(Icons.delete_sweep, size: 18),
                                  label: const Text('Clear All'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _subjectCodeController.dispose();
    _roomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _overviewController.dispose();
    _endDateController.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Map Picker Dialog with Location Search & Reverse Geocoding
// ═══════════════════════════════════════════════════════════════════════════
class MapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerDialog({Key? key, this.initialLat, this.initialLng})
      : super(key: key);

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;
  String? _locationError;
  String? _selectedAddress;
  String? _selectedStreet;
  Set<Marker> _markers = {};

  static const LatLng _defaultLocation = LatLng(22.3193, 114.1694); // HK

  final TextEditingController _searchController = TextEditingController();
  final PlacesSearchService _placesService = PlacesSearchService();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounceTimer;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _updateMarker(_selectedLocation!);
      _isLoadingLocation = false;
      _reverseGeocode(_selectedLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackLocation('Location services are disabled. Please enable GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fallbackLocation('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _fallbackLocation(
          'Location permission permanently denied. Please enable in settings.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!mounted) return;

      final loc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = loc;
        _isLoadingLocation = false;
        _locationError = null;
      });
      _updateMarker(loc);
      _reverseGeocode(loc);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
    } catch (e) {
      if (!mounted) return;
      _fallbackLocation(
        'Could not get location: ${e.toString().split(':').last.trim()}',
      );
    }
  }

  void _fallbackLocation(String error) {
    if (!mounted) return;
    setState(() {
      _locationError = error;
      _selectedLocation = _defaultLocation;
      _isLoadingLocation = false;
    });
    _updateMarker(_defaultLocation);
    _reverseGeocode(_defaultLocation);
  }

  LatLng get _mapCenter => _selectedLocation ?? _defaultLocation;

  void _updateMarker(LatLng pos) {
    _markers
      ..clear()
      ..add(
        Marker(
          markerId: const MarkerId('selected'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    final results = await _placesService.searchPlaces(
      query,
      nearLat: _selectedLocation?.latitude ?? _defaultLocation.latitude,
      nearLng: _selectedLocation?.longitude ?? _defaultLocation.longitude,
      countryCode: 'hk',
    );

    if (!mounted) return;

    setState(() {
      _searchResults = results;
      _showSearchResults = results.isNotEmpty;
      _isSearching = false;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No results found for "$query"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _streetFromResult(PlaceSearchResult result) {
    try {
      final dynamic r = result;
      final String? street = (r.streetName as String?);
      if (street != null && street.trim().isNotEmpty) return street.trim();
    } catch (_) {}
    return _extractStreetFromAddress(result.displayName);
  }

  Future<void> _selectSearchResult(PlaceSearchResult result) async {
    final details = await _placesService.getPlaceDetails(result.placeId);
    if (details == null || details.lat == null || details.lng == null) return;

    final loc = LatLng(details.lat!, details.lng!);

    setState(() {
      _selectedLocation = loc;
      _selectedAddress = details.displayName;
      _selectedStreet = details.streetName ?? details.shortName;
      _searchController.text = details.shortName;
      _showSearchResults = false;
      _searchResults = [];
    });

    _updateMarker(loc);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
  }

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() => _isReverseGeocoding = true);

    final address = await _placesService.reverseGeocode(
      location.latitude,
      location.longitude,
    );

    if (!mounted) return;

    if (address != null && address.trim().isNotEmpty) {
      setState(() {
        _selectedAddress = address.trim();
        _selectedStreet = _extractStreetFromAddress(address);
        _isReverseGeocoding = false;
      });
    } else {
      setState(() => _isReverseGeocoding = false);
    }
  }

  String _extractStreetFromAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return '';
    return parts.first;
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _selectedAddress = null;
      _selectedStreet = null;
      _showSearchResults = false;
    });
    _updateMarker(latLng);
    _reverseGeocode(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Search by street/place and confirm exact coordinates',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),

            if (_locationError != null && !_isLoadingLocation) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Retry', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            Expanded(
              child: _isLoadingLocation
                  ? _buildLoadingView()
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            _buildSearchField(),
                            const SizedBox(height: 8),
                            Expanded(child: _buildMap()),
                          ],
                        ),
                        if (_showSearchResults && _searchResults.isNotEmpty)
                          Positioned(
                            top: 52,
                            left: 0,
                            right: 0,
                            child: _buildSearchResults(),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            if (_selectedLocation != null && !_isLoadingLocation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedStreet != null &&
                              _selectedStreet!.trim().isNotEmpty)
                            Text(
                              _selectedStreet!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_selectedAddress != null)
                            Text(
                              _selectedAddress!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_isReverseGeocoding)
                            Text(
                              'Looking up address...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                            'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
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
              ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_isLoadingLocation ? 'Locating...' : 'My Location'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      height: 44,
                      child: ElevatedButton(
                        onPressed:
                            _selectedLocation != null && !_isLoadingLocation
                                ? () {
                                    Navigator.of(context).pop({
                                      'lat': _selectedLocation!.latitude,
                                      'lng': _selectedLocation!.longitude,
                                      'address': _selectedAddress,
                                      'street': _selectedStreet,
                                    });
                                  }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Getting your location...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Please allow location access when prompted',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedLocation = _defaultLocation;
                _isLoadingLocation = false;
                _locationError = 'Skipped location detection';
              });
              _updateMarker(_defaultLocation);
              _reverseGeocode(_defaultLocation);
            },
            child: const Text('Skip and use default location'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: FormUi.inputDecoration(
          hintText: 'Search by name, address, or street…',
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showSearchResults = false;
                        });
                      },
                    )
                  : null,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSearchResults() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final r = _searchResults[index];
            final street = _streetFromResult(r);

            return InkWell(
              onTap: () => _selectSearchResult(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            street.isNotEmpty ? street : r.shortName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.lat?.toStringAsFixed(6) ?? '--'}, ${r.lng?.toStringAsFixed(6) ?? '--'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (r.type.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r.type,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 15),
        markers: _markers,
        onTap: _onMapTap,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Create School Dialog with Map Picker
// ═══════════════════════════════════════════════════════════════════════════
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
  final TextEditingController _locationController = TextEditingController();

  double? selectedLat;
  double? selectedLng;
  String? selectedAddress;
  String? selectedStreet;

  bool isSaving = false;
  String? errorMessage;

  Future<void> _openMapPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          MapPickerDialog(initialLat: selectedLat, initialLng: selectedLng),
    );

    if (result != null) {
      setState(() {
        selectedLat = result['lat'] as double?;
        selectedLng = result['lng'] as double?;
        selectedAddress = result['address'] as String?;
        selectedStreet = result['street'] as String?;

        if (selectedStreet != null && selectedStreet!.trim().isNotEmpty) {
          _locationController.text = selectedStreet!;
        } else if (selectedAddress != null &&
            selectedAddress!.trim().isNotEmpty) {
          _locationController.text = selectedAddress!;
        } else if (selectedLat != null && selectedLng != null) {
          _locationController.text =
              'Lat: ${selectedLat!.toStringAsFixed(6)}, Lng: ${selectedLng!.toStringAsFixed(6)}';
        } else {
          _locationController.clear();
        }
      });
    }
  }

  Future<void> _createSchool() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter school name');
      return;
    }
    if (selectedLat == null || selectedLng == null) {
      setState(() => errorMessage = 'Please select a location on the map');
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final request = CreateSchoolReq(
        _nameController.text.trim(),
        GpsLocation(selectedLat!, selectedLng!),
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
      backgroundColor: Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
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
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
              decoration: FormUi.inputDecoration(hintText: 'Enter school name'),
            ),
            const SizedBox(height: 24),

            Text(
              'GPS Location *',
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
                    controller: _locationController,
                    readOnly: true,
                    decoration: FormUi.inputDecoration(
                      hintText: 'Search & select location on map',
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: _openMapPicker,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map, color: Colors.white, size: 20),
                    label: const Text('Map', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),

            if (selectedAddress != null &&
                selectedAddress!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  selectedAddress!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            if (selectedLat != null && selectedLng != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'GPS: ${selectedLat!.toStringAsFixed(6)}, ${selectedLng!.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  height: 44,
                  child: TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _createSchool,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}