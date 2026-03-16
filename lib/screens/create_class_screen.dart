import 'dart:async';
import 'package:flutter/material.dart';
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

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

/// 已上傳文件項目
class UploadedFileItem {
  final String originalName;
  final String path;
  final String url;
  final int size;
  final String mimetype;

  UploadedFileItem({
    required this.originalName,
    required this.path,
    required this.url,
    required this.size,
    required this.mimetype,
  });
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
  List<UploadedFileItem> uploadedFiles = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isUploading = false;
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
      final futures = await Future.wait([
        _schoolApi.getSchools(),
        _usersApi.getUsers(role: 'tutor'),
      ]);

      final schoolsRes = futures[0] as SchoolListRes;
      final tutorsRes = futures[1] as dynamic;

      setState(() {
        schools = schoolsRes.items;
        tutors = tutorsRes.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
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
          'jpeg'
        ],
        allowMultiple: true,
        withData: true, // 確保文件數據可用於 Web
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => isUploading = true);

      for (var file in result.files) {
        try {
          MultipartFile multipartFile;

          // Web 平台使用 bytes，其他平台使用 path
          if (file.bytes != null) {
            // Web 平台
            multipartFile = MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            );
          } else if (file.path != null) {
            // 桌面/移動平台
            multipartFile = await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            );
          } else {
            continue; // 跳過無效文件
          }

          final request = UploadFileReq(multipartFile);
          final response = await _filesApi.uploadFile(request);

          if (!mounted) return;
          setState(() {
            uploadedFiles.add(UploadedFileItem(
              originalName: response.file.originalName,
              path: response.file.path,
              url: response.file.url,
              size: response.file.size.toInt(),
              mimetype: response.file.mimetype,
            ));
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${file.name} uploaded successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('❌ Failed to upload ${file.name}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() => isUploading = false);
    } catch (e) {
      setState(() => isUploading = false);
      _showError('File upload failed: ${e.toString()}');
    }
  }

  /// 刪除已上傳的文件
  void _removeFile(int index) {
    setState(() {
      uploadedFiles.removeAt(index);
    });
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 根據文件類型返回圖標
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

  /// 根據重複規則生成時間戳
  List<CourseTimestampReq> _generateTimestamps() {
    if (!isRecurring || startDateTime == null || endDateTime == null) {
      return [
        CourseTimestampReq(
          startDateTime!.millisecondsSinceEpoch,
          endDateTime!.millisecondsSinceEpoch,
        )
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

  /// 獲取預覽的會話數量
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

  /// 顯示次數輸入對話框
  Future<void> _showOccurrencesDialog() async {
    final controller = TextEditingController(
      text: recurrenceOccurrences?.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Number of Occurrences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How many class sessions should be created?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., 4',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
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
              child: Text('Cancel'),
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
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
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
    // Validate required fields
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

    // Validate recurrence settings
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

    // Generate timestamps (supports recurrence)
    final timestamps = _generateTimestamps();
    if (timestamps.isEmpty) return; // _generateTimestamps already shows error

    setState(() => isSaving = true);

    try {
      // Build file paths list
      final filePaths = uploadedFiles.map((f) => f.path).toList();

      final request = CreateCourseReq(
        _classNameController.text.trim(),
        _overviewController.text.trim(),
        _roomController.text.trim(),
        filePaths,
        selectedSchoolId!,
        selectedTutorId!,
        timestamps,
        _subjectCodeController.text.trim().toUpperCase(), // 轉大寫
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/class/create'),
        body: Center(child: CircularProgressIndicator()),
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
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading data'),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _loadData, child: Text('Retry')),
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
            constraints: BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Create New Class',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Class Name
                  CustomTextField(
                    label: 'Class Name *',
                    placeholder: 'e.g., Mathematics Level 1',
                    controller: _classNameController,
                  ),
                  const SizedBox(height: 24),

                  // Subject Code
                  CustomTextField(
                    label: 'Subject Code *',
                    placeholder: 'e.g., MATH',
                    controller: _subjectCodeController,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 24),

                  // Start Date and Time
                  _buildDateTimeField(
                      'Start Date and Time *', _startTimeController, (dt) {
                    setState(() => startDateTime = dt);
                  }),
                  const SizedBox(height: 24),

                  // End Date and Time
                  _buildDateTimeField(
                      'End Date and Time *', _endTimeController, (dt) {
                    setState(() => endDateTime = dt);
                  }),
                  const SizedBox(height: 24),

                  // School Dropdown
                  _buildSchoolDropdown(),
                  const SizedBox(height: 24),

                  // Room
                  CustomTextField(
                    label: 'Room',
                    placeholder: 'e.g., Room 301',
                    controller: _roomController,
                  ),
                  const SizedBox(height: 24),

                  // Tutor Dropdown
                  _buildTutorDropdown(),
                  const SizedBox(height: 24),

                  // Overview / Notification Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview / Notification Content *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _overviewController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Class description and notification content for tutors',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════
                  // Recurring Class Section
                  // ═══════════════════════════════════════════════════════
                  _buildRecurringSection(),
                  const SizedBox(height: 24),

                  // Upload Teaching Materials
                  _buildUploadSection(),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              isSaving ? null : () => context.go('/class'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            side: BorderSide(color: AppColors.inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () => _saveClass(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSaving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text('Save',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
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

  // ═══════════════════════════════════════════════════════════════════════
  // Recurring Class Section
  // ═══════════════════════════════════════════════════════════════════════
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
                    // Reset recurrence settings when disabled
                    selectedFrequency = null;
                    recurrenceInterval = 1;
                    recurrenceOccurrences = null;
                    recurrenceEndDate = null;
                  }
                });
              },
            ),
            Text(
              'Recurring Class',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Create multiple class sessions at regular intervals (weekly, bi-weekly, or monthly)',
              child: Icon(Icons.info_outline,
                  size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
        if (isRecurring) ...[
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Frequency Selection ──────────────────────────────
                Text(
                  'Repeat',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<RecurrenceFrequency>(
                            value: selectedFrequency,
                            hint: Text('Select frequency'),
                            isExpanded: true,
                            items: [
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('every',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '1',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          setState(() {
                            recurrenceInterval = int.tryParse(value) ?? 1;
                            if (recurrenceInterval < 1) recurrenceInterval = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getIntervalUnitLabel(),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── End Condition ────────────────────────────────────
                Text(
                  'End Condition',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose one: end by date or by number of occurrences',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // ── End Date Button ──────────────────────────────
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: recurrenceEndDate ??
                                startDateTime ??
                                DateTime.now(),
                            firstDate: startDateTime ?? DateTime.now(),
                            lastDate:
                                DateTime.now().add(Duration(days: 365 * 2)),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                            // Clear button
                            if (recurrenceEndDate != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => recurrenceEndDate = null);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.close,
                                      size: 16, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Occurrences Button ───────────────────────────
                    Expanded(
                      child: TextButton(
                        onPressed: _showOccurrencesDialog,
                        style: TextButton.styleFrom(
                          backgroundColor: recurrenceOccurrences != null
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.inputBackground,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                            // Clear button
                            if (recurrenceOccurrences != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => recurrenceOccurrences = null);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.close,
                                      size: 16, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Session Preview ──────────────────────────────────
                if (recurrenceEndDate != null ||
                    recurrenceOccurrences != null) ...[
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final sessionCount = _getPreviewSessionCount();
                    final hasRequiredFields = startDateTime != null &&
                        endDateTime != null &&
                        selectedFrequency != null;

                    return Container(
                      padding: EdgeInsets.all(12),
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
                  }),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 獲取重複頻率的單位標籤
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

  /// 獲取重複摘要文字
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
      'Sunday'
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

  // ═══════════════════════════════════════════════════════════════════════
  // Upload Section
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upload Teaching Materials',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'PDF, PPT, DOC, XLS, Images (Max 10MB each)',
              child: Icon(Icons.info_outline,
                  size: 18, color: AppColors.textSecondary),
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
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.inputBackground,
          ),
          child: isUploading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
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
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
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
                              color:
                                  AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _uploadFiles,
                            icon: Icon(Icons.folder_open, size: 18),
                            label: Text('Browse Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: uploadedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = uploadedFiles[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.cardBorder),
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
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                _formatFileSize(file.size),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _removeFile(index),
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
                                  icon: Icon(Icons.add, size: 18),
                                  label: Text('Add More Files'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => setState(
                                      () => uploadedFiles.clear()),
                                  icon:
                                      Icon(Icons.delete_sweep, size: 18),
                                  label: Text('Clear All'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red),
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

  Widget _buildDateTimeField(String label, TextEditingController controller,
      Function(DateTime) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'YYYY/MM/DD HH:MM',
            hintStyle:
                TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            suffixIcon:
                Icon(Icons.calendar_today, color: AppColors.textSecondary),
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
          onTap: () async {
            final now = DateTime.now();
            DateTime? date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
            );
            if (date != null) {
              TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                final dateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );

                // Validate: start time must be later than current time
                if (label.contains('Start') && dateTime.isBefore(now)) {
                  _showError('Start time must be later than current time');
                  return;
                }

                // Validate: end time must be later than start time and current time
                if (label.contains('End')) {
                  if (dateTime.isBefore(now)) {
                    _showError('End time must be later than current time');
                    return;
                  }
                  if (startDateTime != null && dateTime.isBefore(startDateTime!)) {
                    _showError('End time must be later than start time');
                    return;
                  }
                }

                controller.text =
                    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                onSelected(dateTime);
              }
            }
          },
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildSchoolDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSchoolId,
              hint: Text('Select School',
                  style: TextStyle(color: AppColors.textSecondary)),
              isExpanded: true,
              icon: Icon(Icons.unfold_more, color: AppColors.textSecondary),
              items: [
                // Create New School Option
                DropdownMenuItem<String>(
                  value: '__create_new__',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 20, color: AppColors.primary),
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
                // Divider
                DropdownMenuItem<String>(
                  enabled: false,
                  child: Divider(height: 1),
                ),
                // Existing schools
                ...schools.map((school) => DropdownMenuItem(
                      value: school.id,
                      child: Text(school.name),
                    )),
              ],
              onChanged: (value) {
                if (value == '__create_new__') {
                  _showCreateSchoolDialog();
                } else {
                  setState(() => selectedSchoolId = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tutor *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTutorId,
              hint: Text('Select Tutor',
                  style: TextStyle(color: AppColors.textSecondary)),
              isExpanded: true,
              icon: Icon(Icons.unfold_more, color: AppColors.textSecondary),
              items: tutors
                  .map((tutor) => DropdownMenuItem(
                        value: tutor.id,
                        child: Text(tutor.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedTutorId = value);
              },
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
// (Full replacement)
// ═══════════════════════════════════════════════════════════════════════════
class MapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerDialog({
    Key? key,
    this.initialLat,
    this.initialLng,
  }) : super(key: key);

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  // ── Location state ─────────────────────────────────────────────────────
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;
  String? _locationError;
  String? _selectedAddress; // 完整地址
  String? _selectedStreet;  // 街道名稱（若可取得）
  Set<Marker> _markers = {};

  static const LatLng _defaultLocation = LatLng(22.3193, 114.1694); // HK

  // ── Search state ───────────────────────────────────────────────────────
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

  // ── Geolocation ────────────────────────────────────────────────────────
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

  // ── Search ─────────────────────────────────────────────────────────────
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

    // 避免太短查詢造成雜訊
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
      countryCode: 'hk', // 若需全球可改為 null
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
    // 兼容：若 model 有 streetName 欄位就用它；沒有就從 displayName 推估
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

  // ── Reverse geocoding ──────────────────────────────────────────────────
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
    // 簡單策略：取逗號前第一段，通常是門牌+街道
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return '';
    return parts.first;
  }

  // ── Map tap ────────────────────────────────────────────────────────────
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
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Icons.close),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: TextStyle(color: Colors.orange[800], fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: Text('Retry', style: TextStyle(fontSize: 12)),
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
                              style: TextStyle(
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
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location, size: 18),
                  label: Text(_isLoadingLocation ? 'Locating...' : 'My Location'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
                        child: Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _selectedLocation != null && !_isLoadingLocation
                            ? () {
                                Navigator.of(context).pop({
                                  'lat': _selectedLocation!.latitude,
                                  'lng': _selectedLocation!.longitude,
                                  'address': _selectedAddress, // 完整地址
                                  'street': _selectedStreet,   // 街道名稱
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
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
          CircularProgressIndicator(),
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
            child: Text('Skip and use default location'),
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
        decoration: InputDecoration(
          hintText: 'Search by name, address, or street…',
          hintStyle: TextStyle(fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _isSearching
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showSearchResults = false;
                        });
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            street.isNotEmpty ? street : r.shortName,
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.displayName,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.lat?.toStringAsFixed(6) ?? '--'}, ${r.lng?.toStringAsFixed(6) ?? '--'}',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (r.type.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r.type,
                          style: TextStyle(fontSize: 11, color: AppColors.primary),
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
// (Full replacement)
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
  String? selectedAddress; // 完整地址
  String? selectedStreet;  // 街道名（可選）

  bool isSaving = false;
  String? errorMessage;

  Future<void> _openMapPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => MapPickerDialog(
        initialLat: selectedLat,
        initialLng: selectedLng,
      ),
    );

    if (result != null) {
      setState(() {
        selectedLat = result['lat'] as double?;
        selectedLng = result['lng'] as double?;
        selectedAddress = result['address'] as String?;
        selectedStreet = result['street'] as String?;

        // 輸入框優先顯示街道，其次完整地址，最後顯示座標
        if (selectedStreet != null && selectedStreet!.trim().isNotEmpty) {
          _locationController.text = selectedStreet!;
        } else if (selectedAddress != null && selectedAddress!.trim().isNotEmpty) {
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
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New School',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error
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
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
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

            // GPS Location
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
                    decoration: InputDecoration(
                      hintText: 'Search & select location on map',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      prefixIcon:
                          Icon(Icons.location_on, color: AppColors.textSecondary),
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
                    onTap: _openMapPicker,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _openMapPicker,
                    icon: Icon(Icons.map, color: Colors.white, size: 20),
                    label: Text('Map', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),

            if (selectedAddress != null && selectedAddress!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  selectedAddress!,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  height: 44,
                  child: TextButton(
                    onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
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
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Create School',
                            style: TextStyle(color: Colors.white)),
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
