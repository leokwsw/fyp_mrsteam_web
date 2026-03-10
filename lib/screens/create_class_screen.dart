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

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({Key? key}) : super(key: key);

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
        allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx', 'png', 'jpg', 'jpeg'],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to upload ${file.name}: ${e.toString()}'),
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
    if (mimetype.contains('word') || mimetype.contains('document')) return Icons.description;
    if (mimetype.contains('powerpoint') || mimetype.contains('presentation')) return Icons.slideshow;
    if (mimetype.contains('excel') || mimetype.contains('spreadsheet')) return Icons.table_chart;
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

    return generateRecurrenceTimestamps(
      startDateTime: startDateTime!,
      endDateTime: endDateTime!,
      frequency: selectedFrequency!,
      interval: recurrenceInterval,
      endDate: recurrenceEndDate,
      occurrenceCount: recurrenceOccurrences,
    );
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

    // Generate timestamps (single session for now)
    final timestamps = [
      CourseTimestampReq(
        startDateTime!.millisecondsSinceEpoch,
        endDateTime!.millisecondsSinceEpoch,
      )
    ];

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class created successfully'),
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

                  // Room
                  CustomTextField(
                    label: 'Room',
                    placeholder: 'e.g., Room 301',
                    controller: _roomController,
                  ),
                  const SizedBox(height: 24),

                  // Start Date and Time
                  _buildDateTimeField('Start Date and Time *', _startTimeController, (dt) {
                    startDateTime = dt;
                  }),
                  const SizedBox(height: 24),

                  // End Date and Time
                  _buildDateTimeField('End Date and Time *', _endTimeController, (dt) {
                    endDateTime = dt;
                  }),
                  const SizedBox(height: 24),

                  // School Dropdown
                  _buildSchoolDropdown(),
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
                          hintText: 'Class description and notification content for tutors',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.6),
                            fontSize: 14,
                          ),
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recurring Class Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isRecurring,
                            onChanged: (value) {
                              setState(() => isRecurring = value ?? false);
                            },
                          ),
                          Text(
                            'Recurring Class',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
                              // Frequency Selection
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
                                  Text('every', style: TextStyle(color: AppColors.textSecondary)),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: '1',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged: (value) {
                                        recurrenceInterval = int.tryParse(value) ?? 1;
                                        if (recurrenceInterval < 1) recurrenceInterval = 1;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // End Condition
                              Text(
                                'End Condition',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: recurrenceEndDate == null
                                          ? () async {
                                              final date = await showDatePicker(
                                                context: context,
                                                initialDate: startDateTime ?? DateTime.now(),
                                                firstDate: startDateTime ?? DateTime.now(),
                                                lastDate: DateTime.now().add(Duration(days: 365)),
                                              );
                                              if (date != null) {
                                                setState(() {
                                                  recurrenceEndDate = date;
                                                  recurrenceOccurrences = null;
                                                });
                                              }
                                            }
                                          : null,
                                      style: TextButton.styleFrom(
                                        backgroundColor: recurrenceEndDate != null
                                            ? AppColors.primary.withOpacity(0.1)
                                            : AppColors.inputBackground,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: recurrenceOccurrences == null
                                          ? () async {
                                              final result = await showDialog<String>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text('Number of Occurrences'),
                                                  content: TextField(
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(
                                                      hintText: 'Enter number (e.g., 10)',
                                                    ),
                                                    onChanged: (value) {
                                                      Navigator.of(context).pop(value);
                                                    },
                                                  ),
                                                ),
                                              );
                                              if (result != null) {
                                                final count = int.tryParse(result);
                                                if (count != null && count > 0) {
                                                  setState(() {
                                                    recurrenceOccurrences = count;
                                                    recurrenceEndDate = null;
                                                  });
                                                }
                                              }
                                            }
                                          : null,
                                      style: TextButton.styleFrom(
                                        backgroundColor: recurrenceOccurrences != null
                                            ? AppColors.primary.withOpacity(0.1)
                                            : AppColors.inputBackground,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.repeat_one,
                                            size: 18,
                                            color: recurrenceOccurrences != null
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            recurrenceOccurrences != null
                                                ? '${recurrenceOccurrences} times'
                                                : 'Occurrences',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: recurrenceOccurrences != null
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (recurrenceEndDate != null || recurrenceOccurrences != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Will generate multiple class sessions based on your settings',
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Upload Teaching Materials
                  Column(
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
                                            color: AppColors.textSecondary.withOpacity(0.7),
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
                                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              file.originalName,
                                                              style: TextStyle(
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
                                                        icon: Icon(Icons.delete_outline, color: Colors.red),
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
                                                icon: Icon(Icons.add, size: 18),
                                                label: Text('Add More Files'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              OutlinedButton.icon(
                                                onPressed: () => setState(() => uploadedFiles.clear()),
                                                icon: Icon(Icons.delete_sweep, size: 18),
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
                  ),
                  const SizedBox(height: 40),

                  // Action Buttons
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
                          child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

  Widget _buildDateTimeField(String label, TextEditingController controller, Function(DateTime) onSelected) {
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
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            suffixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary),
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
              hint: Text('Select School', style: TextStyle(color: AppColors.textSecondary)),
              isExpanded: true,
              icon: Icon(Icons.unfold_more, color: AppColors.textSecondary),
              items: [
                // Create New School Option
                DropdownMenuItem<String>(
                  value: '__create_new__',
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
              hint: Text('Select Tutor', style: TextStyle(color: AppColors.textSecondary)),
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

// Map Picker Dialog with User Location
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
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoadingLocation = true;
  String? _locationError;

  // Default location (Hong Kong) as fallback
  static const LatLng _defaultLocation = LatLng(22.3193, 114.1694);
  Set<Marker> _markers = {};
  
  // Search
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  
  // Google Places API
  static const String _placesApiKey = 'AIzaSyAbS02DKq5kL1nN5cNIHBtluCrvSGr633c';
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';

  @override
  void initState() {
    super.initState();

    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _markers.add(
        Marker(
          markerId: MarkerId('selected'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _isLoadingLocation = false;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _selectedLocation = _defaultLocation;
          _isLoadingLocation = false;
        });
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied. Please allow location access.';
            _selectedLocation = _defaultLocation;
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied. Please enable in browser settings.';
          _selectedLocation = _defaultLocation;
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position with longer timeout for web
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
          _locationError = null;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId('user_location'),
              position: _selectedLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        });

        // Move map to user location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not get location: ${e.toString().split(':').last.trim()}';
          _selectedLocation = _defaultLocation;
          _isLoadingLocation = false;
        });
      }
    }
  }

  LatLng get _mapCenter {
    return _selectedLocation ?? _defaultLocation;
  }
  
  // Search with debounce
  Timer? _debounceTimer;
  
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        setState(() {
          _predictions = [];
          _showSearchResults = false;
        });
        return;
      }
      
      _performSearch(query);
    });
  }
  
  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });
    
    try {
      // Use backend proxy for Google Places API
      final baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=AIzaSyAbS02DKq5kL1nN5cNIHBtluCrvSGr633c'
        '&location=22.3193,114.1694'
        '&radius=50000'
        '&components=country:HK'
        '&language=en';
      
      // TODO: Replace with your backend proxy URL once added
      // final proxyUrl = 'https://fyp-backend-zknqk6dfca-de.a.run.app/api/v1/places/proxy?url=${Uri.encodeComponent(baseUrl)}';
      
      // For now, use local search (will be replaced with proxy)
      await Future.delayed(Duration(milliseconds: 100));
      _performLocalSearch(query);
      
    } catch (e) {
      print('Search error: $e');
      _performLocalSearch(query);
    }
  }
  
  // Local search for Hong Kong locations (comprehensive database)
  void _performLocalSearch(String query) {
    final queryLower = query.toLowerCase();
    
    // Comprehensive Hong Kong locations database
    final hkPlaces = [
      // Hong Kong Island - Central & Western
      {'id': 'central', 'name': 'Central', 'area': 'Central & Western', 'type': 'MTR'},
      {'id': 'sheung_wan', 'name': 'Sheung Wan', 'area': 'Central & Western', 'type': 'MTR'},
      {'id': 'sai_ying_pun', 'name': 'Sai Ying Pun', 'area': 'Central & Western', 'type': 'MTR'},
      {'id': 'hku', 'name': 'HKU', 'area': 'Central & Western', 'type': 'MTR'},
      {'id': 'kennedy_town', 'name': 'Kennedy Town', 'area': 'Central & Western', 'type': 'MTR'},
      
      // Hong Kong Island - Wan Chai
      {'id': 'wan_chai', 'name': 'Wan Chai', 'area': 'Wan Chai', 'type': 'MTR'},
      {'id': 'admiralty', 'name': 'Admiralty', 'area': 'Wan Chai', 'type': 'MTR'},
      {'id': 'causeway_bay', 'name': 'Causeway Bay', 'area': 'Wan Chai', 'type': 'MTR'},
      {'id': 'happy_valley', 'name': 'Happy Valley', 'area': 'Wan Chai', 'type': 'Area'},
      {'id': 'so_cong_po', 'name': 'So Cong Po', 'area': 'Wan Chai', 'type': 'Area'},
      
      // Hong Kong Island - Eastern
      {'id': 'quarry_bay', 'name': 'Quarry Bay', 'area': 'Eastern', 'type': 'MTR'},
      {'id': 'tai_koo', 'name': 'Tai Koo', 'area': 'Eastern', 'type': 'MTR'},
      {'id': 'sai_wan_ho', 'name': 'Sai Wan Ho', 'area': 'Eastern', 'type': 'MTR'},
      {'id': 'shau_kei_wan', 'name': 'Shau Kei Wan', 'area': 'Eastern', 'type': 'MTR'},
      {'id': 'chai_wan', 'name': 'Chai Wan', 'area': 'Eastern', 'type': 'MTR'},
      {'id': 'north_point', 'name': 'North Point', 'area': 'Eastern', 'type': 'MTR'},
      
      // Hong Kong Island - Southern
      {'id': 'aberdeen', 'name': 'Aberdeen', 'area': 'Southern', 'type': 'Area'},
      {'id': 'repulse_bay', 'name': 'Repulse Bay', 'area': 'Southern', 'type': 'Area'},
      {'id': 'stanley', 'name': 'Stanley', 'area': 'Southern', 'type': 'Area'},
      {'id': 'ocean_park', 'name': 'Ocean Park', 'area': 'Southern', 'type': 'Landmark'},
      
      // Kowloon - Yau Tsim Mong
      {'id': 'tsim_sha_tsui', 'name': 'Tsim Sha Tsui', 'area': 'Yau Tsim Mong', 'type': 'MTR'},
      {'id': 'mong_kok', 'name': 'Mong Kok', 'area': 'Yau Tsim Mong', 'type': 'MTR'},
      {'id': 'yau_ma_te', 'name': 'Yau Ma Tei', 'area': 'Yau Tsim Mong', 'type': 'MTR'},
      {'id': 'jordan', 'name': 'Jordan', 'area': 'Yau Tsim Mong', 'type': 'MTR'},
      {'id': 'west_kowloon', 'name': 'West Kowloon', 'area': 'Yau Tsim Mong', 'type': 'Area'},
      
      // Kowloon - Sham Shui Po
      {'id': 'sham_shui_po', 'name': 'Sham Shui Po', 'area': 'Sham Shui Po', 'type': 'MTR'},
      {'id': 'cheung_sha_wan', 'name': 'Cheung Sha Wan', 'area': 'Sham Shui Po', 'type': 'MTR'},
      {'id': 'lai_chi_kok', 'name': 'Lai Chi Kok', 'area': 'Sham Shui Po', 'type': 'MTR'},
      {'id': 'mei_foo', 'name': 'Mei Foo', 'area': 'Sham Shui Po', 'type': 'MTR'},
      
      // Kowloon - Kowloon City
      {'id': 'kowloon_tong', 'name': 'Kowloon Tong', 'area': 'Kowloon City', 'type': 'MTR'},
      {'id': 'lok_fu', 'name': 'Lok Fu', 'area': 'Kowloon City', 'type': 'MTR'},
      {'id': 'wang_tau_hom', 'name': 'Wang Tau Hom', 'area': 'Kowloon City', 'type': 'MTR'},
      {'id': 'hung_hom', 'name': 'Hung Hom', 'area': 'Kowloon City', 'type': 'MTR'},
      {'id': 'to_kwa_wan', 'name': 'To Kwa Wan', 'area': 'Kowloon City', 'type': 'Area'},
      {'id': 'kai_tak', 'name': 'Kai Tak', 'area': 'Kowloon City', 'type': 'Area'},
      
      // Kowloon - Wong Tai Sin
      {'id': 'prince_edward', 'name': 'Prince Edward', 'area': 'Wong Tai Sin', 'type': 'MTR'},
      {'id': 'wong_tai_sin', 'name': 'Wong Tai Sin', 'area': 'Wong Tai Sin', 'type': 'MTR'},
      {'id': 'diamond_hill', 'name': 'Diamond Hill', 'area': 'Wong Tai Sin', 'type': 'MTR'},
      {'id': 'choi_hung', 'name': 'Choi Hung', 'area': 'Wong Tai Sin', 'type': 'MTR'},
      
      // Kowloon - Kwun Tong
      {'id': 'kwun_tong', 'name': 'Kwun Tong', 'area': 'Kwun Tong', 'type': 'MTR'},
      {'id': 'ngau_tau_kok', 'name': 'Ngau Tau Kok', 'area': 'Kwun Tong', 'type': 'MTR'},
      {'id': 'kowloon_bay', 'name': 'Kowloon Bay', 'area': 'Kwun Tong', 'type': 'MTR'},
      {'id': 'lam_tin', 'name': 'Lam Tin', 'area': 'Kwun Tong', 'type': 'MTR'},
      {'id': 'sau_mau_ping', 'name': 'Sau Mau Ping', 'area': 'Kwun Tong', 'type': 'Area'},
      
      // New Territories - Tsuen Wan
      {'id': 'tsuen_wan', 'name': 'Tsuen Wan', 'area': 'Tsuen Wan', 'type': 'MTR'},
      {'id': 'tsuen_wan_west', 'name': 'Tsuen Wan West', 'area': 'Tsuen Wan', 'type': 'MTR'},
      {'id': 'kwai_fong', 'name': 'Kwai Fong', 'area': 'Tsuen Wan', 'type': 'MTR'},
      {'id': 'kwai_hing', 'name': 'Kwai Hing', 'area': 'Tsuen Wan', 'type': 'MTR'},
      {'id': 'lai_king', 'name': 'Lai King', 'area': 'Tsuen Wan', 'type': 'MTR'},
      
      // New Territories - Tuen Mun
      {'id': 'tuen_mun', 'name': 'Tuen Mun', 'area': 'Tuen Mun', 'type': 'MTR'},
      {'id': 'siu_hong', 'name': 'Siu Hong', 'area': 'Tuen Mun', 'type': 'MTR'},
      {'id': 'hung_shui_kiu', 'name': 'Hung Shui Kiu', 'area': 'Tuen Mun', 'type': 'Area'},
      
      // New Territories - Yuen Long
      {'id': 'yuen_long', 'name': 'Yuen Long', 'area': 'Yuen Long', 'type': 'MTR'},
      {'id': 'long_ping', 'name': 'Long Ping', 'area': 'Yuen Long', 'type': 'MTR'},
      {'id': 'tin_shui_wai', 'name': 'Tin Shui Wai', 'area': 'Yuen Long', 'type': 'MTR'},
      
      // New Territories - North
      {'id': 'sheung_shui', 'name': 'Sheung Shui', 'area': 'North', 'type': 'MTR'},
      {'id': 'fanling', 'name': 'Fanling', 'area': 'North', 'type': 'MTR'},
      {'id': 'tai_po', 'name': 'Tai Po', 'area': 'North', 'type': 'MTR'},
      {'id': 'tai_wo', 'name': 'Tai Wo', 'area': 'North', 'type': 'MTR'},
      {'id': 'university', 'name': 'University (CUHK)', 'area': 'North', 'type': 'MTR'},
      
      // New Territories - Sha Tin
      {'id': 'sha_tin', 'name': 'Sha Tin', 'area': 'Sha Tin', 'type': 'MTR'},
      {'id': 'fo_tan', 'name': 'Fo Tan', 'area': 'Sha Tin', 'type': 'MTR'},
      {'id': 'racecourse', 'name': 'Racecourse', 'area': 'Sha Tin', 'type': 'MTR'},
      {'id': 'ma_on_shan', 'name': 'Ma On Shan', 'area': 'Sha Tin', 'type': 'MTR'},
      {'id': 'lei_ung_mun', 'name': 'Lei Ung Mun', 'area': 'Sha Tin', 'type': 'Area'},
      
      // New Territories - Sai Kung
      {'id': 'sai_kung', 'name': 'Sai Kung', 'area': 'Sai Kung', 'type': 'Town'},
      {'id': 'hang_hau', 'name': 'Hang Hau', 'area': 'Sai Kung', 'type': 'MTR'},
      {'id': 'po_lam', 'name': 'Po Lam', 'area': 'Sai Kung', 'type': 'MTR'},
      {'id': 'tiu_keng_leng', 'name': 'Tiu Keng Leng', 'area': 'Sai Kung', 'type': 'MTR'},
      
      // New Territories - Kwai Tsing
      {'id': 'tsing_yi', 'name': 'Tsing Yi', 'area': 'Kwai Tsing', 'type': 'MTR'},
      {'id': 'sunshine', 'name': 'Sunshine', 'area': 'Kwai Tsing', 'type': 'Area'},
      
      // Islands
      {'id': 'tung_chung', 'name': 'Tung Chung', 'area': 'Islands', 'type': 'MTR'},
      {'id': 'airport', 'name': 'Hong Kong Airport', 'area': 'Islands', 'type': 'Landmark'},
      {'id': 'disneyland', 'name': 'Disneyland', 'area': 'Islands', 'type': 'Landmark'},
      {'id': 'mui_wo', 'name': 'Mui Wo (Silvermine Bay)', 'area': 'Islands', 'type': 'Town'},
      {'id': 'cheung_chau', 'name': 'Cheung Chau', 'area': 'Islands', 'type': 'Island'},
      {'id': 'lamma_island', 'name': 'Lamma Island (Yung Shue Wan)', 'area': 'Islands', 'type': 'Island'},
      
      // Major Landmarks
      {'id': 'hk_university', 'name': 'HK University', 'area': 'Pokfulam', 'type': 'University'},
      {'id': 'polyu', 'name': 'HK Polytechnic University', 'area': 'Hung Hom', 'type': 'University'},
      {'id': 'cityu', 'name': 'City University of HK', 'area': 'Kowloon Tong', 'type': 'University'},
      {'id': 'hkust', 'name': 'HK University of Science & Tech', 'area': 'Clear Water Bay', 'type': 'University'},
      {'id': 'cuhk', 'name': 'Chinese University of HK', 'area': 'Sha Tin', 'type': 'University'},
      {'id': 'eduhk', 'name': 'Education University of HK', 'area': 'Tai Po', 'type': 'University'},
      {'id': 'lngant', 'name': 'Lingnan University', 'area': 'Tuen Mun', 'type': 'University'},
      {'id': 'hksc', 'name': 'Hong Kong Science Park', 'area': 'Sha Tin', 'type': 'Landmark'},
      {'id': 'cyberport', 'name': 'Cyberport', 'area': 'Pokfulam', 'type': 'Landmark'},
      {'id': 'asworld', 'name': 'AsiaWorld-Expo', 'area': 'Airport', 'type': 'Landmark'},
    ];
    
    // Filter places by query
    final filtered = hkPlaces.where((place) {
      final name = (place['name'] as String).toLowerCase();
      final area = (place['area'] as String).toLowerCase();
      final type = (place['type'] as String).toLowerCase();
      
      return name.contains(queryLower) ||
             area.contains(queryLower) ||
             type.contains(queryLower);
    }).toList();
    
    // Sort by relevance (exact match first)
    filtered.sort((a, b) {
      final aName = (a['name'] as String).toLowerCase();
      final bName = (b['name'] as String).toLowerCase();
      
      if (aName == queryLower) return -1;
      if (bName == queryLower) return 1;
      if (aName.startsWith(queryLower)) return -1;
      if (bName.startsWith(queryLower)) return 1;
      return 0;
    });
    
    // Build predictions
    final predictions = filtered.map((place) {
      return {
        'place_id': place['id'],
        'description': '${place['name']}, Hong Kong',
        'structured_formatting': {
          'main_text': place['name'],
          'secondary_text': '${place['area']} (${place['type']})',
        },
      };
    }).toList();
    
    setState(() {
      _predictions = predictions;
      _showSearchResults = predictions.isNotEmpty;
      _isSearching = false;
    });
    
    if (predictions.isEmpty && query.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No results for "$query". Try: Central, Mong Kok, TST, etc.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _selectPrediction(Map<String, dynamic> prediction) async {
    setState(() {
      _isSearching = true;
      _showSearchResults = false;
    });
    
    try {
      final placeId = prediction['place_id'] as String;
      
      // All Hong Kong locations with coordinates
      final hkCoords = {
        // Hong Kong Island - Central & Western
        'central': LatLng(22.2783, 114.1747),
        'sheung_wan': LatLng(22.2867, 114.1519),
        'sai_ying_pun': LatLng(22.2866, 114.1425),
        'hku': LatLng(22.2850, 114.1383),
        'kennedy_town': LatLng(22.2816, 114.1312),
        
        // Hong Kong Island - Wan Chai
        'wan_chai': LatLng(22.2783, 114.1747),
        'admiralty': LatLng(22.2793, 114.1638),
        'causeway_bay': LatLng(22.2804, 114.1845),
        'happy_valley': LatLng(22.2707, 114.1804),
        
        // Hong Kong Island - Eastern
        'quarry_bay': LatLng(22.2858, 114.2154),
        'tai_koo': LatLng(22.2846, 114.2262),
        'sai_wan_ho': LatLng(22.2867, 114.2262),
        'shau_kei_wan': LatLng(22.2792, 114.2275),
        'chai_wan': LatLng(22.2654, 114.2312),
        'north_point': LatLng(22.2917, 114.1992),
        
        // Hong Kong Island - Southern
        'aberdeen': LatLng(22.2475, 114.1558),
        'repulse_bay': LatLng(22.2383, 114.1983),
        'stanley': LatLng(22.2167, 114.2167),
        'ocean_park': LatLng(22.2467, 114.1708),
        
        // Kowloon - Yau Tsim Mong
        'tsim_sha_tsui': LatLng(22.2976, 114.1722),
        'mong_kok': LatLng(22.3193, 114.1694),
        'yau_ma_te': LatLng(22.3048, 114.1719),
        'jordan': LatLng(22.3050, 114.1667),
        'west_kowloon': LatLng(22.3033, 114.1600),
        
        // Kowloon - Sham Shui Po
        'sham_shui_po': LatLng(22.3308, 114.1625),
        'cheung_sha_wan': LatLng(22.3383, 114.1583),
        'lai_chi_kok': LatLng(22.3400, 114.1517),
        'mei_foo': LatLng(22.3433, 114.1417),
        
        // Kowloon - Kowloon City
        'kowloon_tong': LatLng(22.3375, 114.1716),
        'lok_fu': LatLng(22.3383, 114.1858),
        'wang_tau_hom': LatLng(22.3417, 114.1875),
        'hung_hom': LatLng(22.3017, 114.1883),
        'to_kwa_wan': LatLng(22.3167, 114.1917),
        'kai_tak': LatLng(22.3267, 114.1967),
        
        // Kowloon - Wong Tai Sin
        'prince_edward': LatLng(22.3212, 114.1694),
        'wong_tai_sin': LatLng(22.3417, 114.1933),
        'diamond_hill': LatLng(22.3400, 114.2017),
        'choi_hung': LatLng(22.3367, 114.2100),
        
        // Kowloon - Kwun Tong
        'kwun_tong': LatLng(22.3117, 114.2217),
        'ngau_tau_kok': LatLng(22.3150, 114.2233),
        'kowloon_bay': LatLng(22.3233, 114.2133),
        'lam_tin': LatLng(22.3067, 114.2317),
        
        // New Territories - Tsuen Wan
        'tsuen_wan': LatLng(22.3667, 114.1167),
        'tsuen_wan_west': LatLng(22.3650, 114.1100),
        'kwai_fong': LatLng(22.3583, 114.1333),
        'kwai_hing': LatLng(22.3633, 114.1400),
        'lai_king': LatLng(22.3483, 114.1350),
        
        // New Territories - Tuen Mun
        'tuen_mun': LatLng(22.3917, 113.9767),
        'siu_hong': LatLng(22.4167, 113.9833),
        
        // New Territories - Yuen Long
        'yuen_long': LatLng(22.4467, 114.0333),
        'long_ping': LatLng(22.4483, 114.0250),
        'tin_shui_wai': LatLng(22.4583, 114.0017),
        
        // New Territories - North
        'sheung_shui': LatLng(22.5017, 114.1283),
        'fanling': LatLng(22.4933, 114.1417),
        'tai_po': LatLng(22.4500, 114.1667),
        'tai_wo': LatLng(22.4517, 114.1583),
        'university': LatLng(22.4167, 114.2000),
        
        // New Territories - Sha Tin
        'sha_tin': LatLng(22.3833, 114.1917),
        'fo_tan': LatLng(22.3967, 114.1967),
        'ma_on_shan': LatLng(22.4217, 114.2283),
        
        // New Territories - Sai Kung
        'sai_kung': LatLng(22.3833, 114.2667),
        'hang_hau': LatLng(22.3233, 114.2617),
        'po_lam': LatLng(22.3200, 114.2550),
        'tiu_keng_leng': LatLng(22.3050, 114.2650),
        
        // New Territories - Kwai Tsing
        'tsing_yi': LatLng(22.3500, 114.1167),
        
        // Islands
        'tung_chung': LatLng(22.2883, 113.9417),
        'airport': LatLng(22.3100, 113.9167),
        'disneyland': LatLng(22.3133, 114.0400),
        'mui_wo': LatLng(22.2667, 114.0000),
        'cheung_chau': LatLng(22.2067, 114.0283),
        'lamma_island': LatLng(22.2333, 114.1000),
        
        // Universities
        'hk_university': LatLng(22.2850, 114.1383),
        'polyu': LatLng(22.3033, 114.1800),
        'cityu': LatLng(22.3383, 114.1717),
        'hkust': LatLng(22.3367, 114.2650),
        'cuhk': LatLng(22.4167, 114.2000),
        'eduhk': LatLng(22.4683, 114.1933),
        'lngant': LatLng(22.4083, 113.9917),
        
        // Landmarks
        'hksc': LatLng(22.4183, 114.2300),
        'cyberport': LatLng(22.2633, 114.1300),
        'asworld': LatLng(22.3150, 113.9333),
      };
      
      final coords = hkCoords[placeId];
      if (coords != null) {
        setState(() {
          _selectedLocation = coords;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId('selected'),
              position: _selectedLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
          _searchController.text = prediction['description'] as String? ?? '';
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      } else {
        // Unknown location, show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not found. Please try another place.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() {
        _isSearching = false;
      });
    } catch (e) {
      print('Select prediction error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        height: 600,
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
            const SizedBox(height: 8),
            Text(
              'Click on the map to select a location',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Search Box with Places API
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _isSearching
                      ? Padding(
                          padding: EdgeInsets.all(12),
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
                                  _predictions = [];
                                  _showSearchResults = false;
                                });
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  _onSearchChanged(value);
                },
              ),
            ),
            
            // Search Results
            if (_showSearchResults && _predictions.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      leading: Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      title: Text(
                        prediction['description'] ?? '',
                        style: TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: prediction['structured_formatting'] != null
                          ? Text(
                              prediction['structured_formatting']['secondary_text'] ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () {
                        _selectPrediction(prediction);
                      },
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),

            // Location Error Warning
            if (_locationError != null && !_isLoadingLocation) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
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
            ],
            const SizedBox(height: 16),

            // Map
            Expanded(
              child: _isLoadingLocation
                  ? Center(
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
                            },
                            child: Text('Skip and use default location'),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: _mapCenter,
                          zoom: 15,
                        ),
                        markers: _markers,
                        onTap: (LatLng latLng) {
                          setState(() {
                            _selectedLocation = latLng;
                            _markers.clear();
                            _markers.add(
                              Marker(
                                markerId: MarkerId('selected'),
                                position: latLng,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                            );
                          });
                        },
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: true,
                        compassEnabled: true,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Selected Coordinates Display
            if (_selectedLocation != null && !_isLoadingLocation)
              Container(
                padding: EdgeInsets.all(12),
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
                      child: Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // My Location Button
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
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Confirm', style: TextStyle(color: Colors.white)),
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
}

// Create School Dialog with Map Picker
class CreateSchoolDialog extends StatefulWidget {
  final Function(SchoolRes) onSchoolCreated;

  const CreateSchoolDialog({Key? key, required this.onSchoolCreated}) : super(key: key);

  @override
  State<CreateSchoolDialog> createState() => _CreateSchoolDialogState();
}

class _CreateSchoolDialogState extends State<CreateSchoolDialog> {
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  double? selectedLat;
  double? selectedLng;

  bool isSaving = false;
  String? errorMessage;

  Future<void> _openMapPicker() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => MapPickerDialog(
        initialLat: selectedLat,
        initialLng: selectedLng,
      ),
    );

    if (result != null) {
      setState(() {
        selectedLat = result['lat'];
        selectedLng = result['lng'];
        _locationController.text = 'Lat: ${selectedLat!.toStringAsFixed(6)}, Lng: ${selectedLng!.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _createSchool() async {
    // Validate
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

            // GPS Location with Map Picker
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
                      hintText: 'Click to select location on map',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      prefixIcon: Icon(Icons.location_on, color: AppColors.textSecondary),
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
            const SizedBox(height: 32),

            // Action Buttons
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Create School', style: TextStyle(color: Colors.white)),
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