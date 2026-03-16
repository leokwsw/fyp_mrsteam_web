import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
import '../data/model/response/res_course.dart';
import '../data/model/response/res_school.dart';
import '../data/model/response/res_user.dart';

class EditClassScreen extends StatefulWidget {
  final String classId;

  const EditClassScreen({Key? key, required this.classId}) : super(key: key);

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
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

  String? selectedSchoolId;
  String? selectedTutorId;
  DateTime? startDateTime;
  DateTime? endDateTime;

  List<SchoolRes> schools = [];
  List<UserResponse> tutors = [];

  /// 統一的文件列表（包含已有文件和新上傳文件）
  List<CourseFileReq> uploadedFiles = [];

  CourseRes? existingCourse;

  bool isLoading = true;
  bool isSaving = false;
  bool isUploading = false;
  bool isLoadingFiles = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime? _parseAnyDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value.toLocal();

    if (value is int) {
      // ms or s timestamp
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
      }
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000).toLocal();
      }
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      final dt = DateTime.tryParse(trimmed);
      if (dt != null) return dt.toLocal();

      final numeric = int.tryParse(trimmed);
      if (numeric != null) {
        if (numeric > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(numeric).toLocal();
        }
        if (numeric > 1000000000) {
          return DateTime.fromMillisecondsSinceEpoch(numeric * 1000).toLocal();
        }
      }
    }

    return null;
  }

  /// 兼容不同 CourseRes 結構，盡可能抓到開始/結束時間
  Map<String, DateTime?> _extractCourseDateTimes(CourseRes course) {
    DateTime? start;
    DateTime? end;

    final dynamic c = course;

    // 1) 優先從 timestamps[0] 讀取
    try {
      final timestamps = c.timestamps;
      if (timestamps is List && timestamps.isNotEmpty) {
        final dynamic first = timestamps.first;
        start ??= _parseAnyDateTime(first.start);
        start ??= _parseAnyDateTime(first.startAt);
        start ??= _parseAnyDateTime(first.startTime);
        start ??= _parseAnyDateTime(first.startTimestamp);
        start ??= _parseAnyDateTime(first.from);

        end ??= _parseAnyDateTime(first.end);
        end ??= _parseAnyDateTime(first.endAt);
        end ??= _parseAnyDateTime(first.endTime);
        end ??= _parseAnyDateTime(first.endTimestamp);
        end ??= _parseAnyDateTime(first.to);
      }
    } catch (_) {}

    // 2) 再嘗試 course 直接字段
    try {
      start ??= _parseAnyDateTime(c.startAt);
      start ??= _parseAnyDateTime(c.startTime);
      start ??= _parseAnyDateTime(c.start);
      start ??= _parseAnyDateTime(c.startTimestamp);

      end ??= _parseAnyDateTime(c.endAt);
      end ??= _parseAnyDateTime(c.endTime);
      end ??= _parseAnyDateTime(c.end);
      end ??= _parseAnyDateTime(c.endTimestamp);
    } catch (_) {}

    return {
      'start': start,
      'end': end,
    };
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
        _courseApi.getCourseById(widget.classId),
      ]);

      final schoolsRes = futures[0] as SchoolListRes;
      final tutorsRes = futures[1] as dynamic;
      final courseRes = futures[2] as CourseRes;

      existingCourse = courseRes;

      final dynamic c = courseRes;
      final timeMap = _extractCourseDateTimes(courseRes);
      final parsedStart = timeMap['start'];
      final parsedEnd = timeMap['end'];

      // Populate form fields
      _classNameController.text = courseRes.name;
      _roomController.text = courseRes.room;
      _overviewController.text = courseRes.overview;
      _subjectCodeController.text = ((c.subjectShortName ?? '') as String).trim();

      _startTimeController.text =
          parsedStart != null ? _formatDateTime(parsedStart) : '';
      _endTimeController.text = parsedEnd != null ? _formatDateTime(parsedEnd) : '';

      selectedSchoolId = courseRes.schoolId;
      selectedTutorId = courseRes.tutorId;

      setState(() {
        schools = schoolsRes.items;
        tutors = tutorsRes.items;

        startDateTime = parsedStart;
        endDateTime = parsedEnd;

        // Validate selected values exist in options
        if (selectedSchoolId != null &&
            !schools.any((s) => s.id == selectedSchoolId)) {
          selectedSchoolId = null;
        }
        if (selectedTutorId != null &&
            !tutors.any((t) => t.id == selectedTutorId)) {
          selectedTutorId = null;
        }

        // 直接使用後端 CourseFile 完整資料（url/path/originalName）
        uploadedFiles = courseRes.files.map((f) {
          final name = f.originalName.isNotEmpty ? f.originalName : f.filename;
          return CourseFileReq(
            originalName: name.isNotEmpty ? name : f.path.split('/').last,
            filename: name.isNotEmpty ? name : f.path.split('/').last,
            path: f.path,
            url: f.url.isNotEmpty ? f.url : '',
            size: 0,
            mimetype: _guessMimetype(name.isNotEmpty ? name : f.path),
            isExisting: true,
          );
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  /// 根據文件名猜測 MIME 類型
  String _guessMimetype(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _buildPublicFileUrl(String path) {
    final encodedPath = Uri.encodeFull(path.trim());
    return 'https://storage.googleapis.com/fyp-uploads/$encodedPath';
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

  /// 上傳新文件
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

          setState(() {
            uploadedFiles.add(CourseFileReq(
              originalName: response.file.originalName,
              filename: response.file.originalName,
              path: response.file.path,
              url: response.file.url,
              size: response.file.size.toInt(),
              mimetype: response.file.mimetype,
            ));
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${file.name} uploaded successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('❌ Failed to upload ${file.name}: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      setState(() => isUploading = false);
    } catch (e) {
      setState(() => isUploading = false);
      _showError('File upload failed: ${e.toString()}');
    }
  }

  /// 刪除文件
  void _removeFile(int index) {
    final file = uploadedFiles[index];
    final fileName = file.originalName;

    // Show confirmation for existing files
    if (file.isExisting) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Remove File',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to remove "$fileName"? This will take effect after saving.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          setState(() => uploadedFiles.removeAt(index));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Remove',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // New files can be removed immediately without confirmation
      setState(() => uploadedFiles.removeAt(index));
    }
  }

  /// 預覽/下載文件
  Future<void> _previewFile(CourseFileReq file) async {
    // A) 優先使用 file.url（你已驗證這個可下載）
    if (file.url.trim().isNotEmpty) {
      html.window.open(file.url, '_blank');
      return;
    }

    // B) 沒有 url，就用 path
    final path = file.path.trim();
    if (path.isEmpty) {
      _showError('File path not available');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('Getting file link...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      // C) 先試 signed-url
      final signedUrlRes = await _filesApi.getSignedUrl(path);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      final url = signedUrlRes.url;
      if (url.isNotEmpty) {
        html.window.open(url, '_blank');
        return;
      }

      // D) signed-url 空字串時 fallback 公開 URL
      final fallback = _buildPublicFileUrl(path);
      html.window.open(fallback, '_blank');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // E) signed-url 失敗也 fallback 公開 URL
      final fallback = _buildPublicFileUrl(path);
      html.window.open(fallback, '_blank');
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
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

  /// 獲取文件類型標籤
  String _getFileExtLabel(String mimetype) {
    if (mimetype.contains('pdf')) return 'PDF';
    if (mimetype.contains('word') || mimetype.contains('document')) return 'DOC';
    if (mimetype.contains('powerpoint') || mimetype.contains('presentation')) {
      return 'PPT';
    }
    if (mimetype.contains('excel') || mimetype.contains('spreadsheet')) {
      return 'XLS';
    }
    if (mimetype.contains('png')) return 'PNG';
    if (mimetype.contains('jpeg') || mimetype.contains('jpg')) return 'JPG';
    if (mimetype.contains('image')) return 'IMG';
    return 'FILE';
  }

  /// 獲取文件類型對應的顏色
  Color _getFileColor(String mimetype) {
    if (mimetype.contains('pdf')) return Colors.red;
    if (mimetype.contains('word') || mimetype.contains('document')) {
      return Colors.blue;
    }
    if (mimetype.contains('powerpoint') || mimetype.contains('presentation')) {
      return Colors.orange;
    }
    if (mimetype.contains('excel') || mimetype.contains('spreadsheet')) {
      return Colors.green;
    }
    if (mimetype.contains('image')) return Colors.purple;
    return Colors.grey;
  }

  Future<void> _saveClass() async {
    // Validate required fields
    if (_classNameController.text.trim().isEmpty) {
      _showError('Please enter class name');
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

    setState(() => isSaving = true);

    try {
      final timestamp = CourseTimestampReq(
        startDateTime!.millisecondsSinceEpoch,
        endDateTime!.millisecondsSinceEpoch,
      );

      final request = UpdateCourseReq(
        name: _classNameController.text.trim(),
        overview: _overviewController.text.trim(),
        room: _roomController.text.trim(),
        files: uploadedFiles,
        schoolId: selectedSchoolId!,
        tutorId: selectedTutorId!,
        timestamps: [timestamp],
        subjectShortName: _subjectCodeController.text.trim().isNotEmpty
            ? _subjectCodeController.text.trim().toUpperCase()
            : null,
      );

      await _courseApi.updateCourse(widget.classId, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/class');
      }
    } catch (e) {
      _showError('Failed to update class: ${e.toString()}');
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Delete Class',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this class? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _deleteClass();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Delete',
                          style: TextStyle(color: Colors.white)),
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

  Future<void> _deleteClass() async {
    setState(() => isSaving = true);

    try {
      await _courseApi.disableCourse(widget.classId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/class');
      }
    } catch (e) {
      _showError('Failed to delete class: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/class/edit'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/class/edit'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading class data'),
              const SizedBox(height: 8),
              Text(errorMessage!,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/class/edit'),
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
                      'Edit Class',
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
                        'Overview / Notification Content',
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

                  // Teaching Materials Section
                  _buildFilesSection(),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Delete Button
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed:
                              isSaving ? null : _showDeleteConfirmation,
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: Colors.white),
                          label: Text('Delete',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Cancel and Save Buttons
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => context.go('/class'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.textPrimary,
                                elevation: 0,
                                side:
                                    BorderSide(color: AppColors.inputBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Cancel',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
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
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Teaching Materials',
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
            const Spacer(),
            if (uploadedFiles.isNotEmpty)
              Text(
                '${uploadedFiles.length} file${uploadedFiles.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isUploading ? AppColors.primary : AppColors.inputBorder,
              width: isUploading ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.inputBackground,
          ),
          child: isLoadingFiles
              ? _buildFilesLoading()
              : isUploading
                  ? _buildUploadingState()
                  : uploadedFiles.isEmpty
                      ? _buildEmptyFilesState()
                      : _buildFilesList(),
        ),

        if (uploadedFiles.isNotEmpty && !isUploading && !isLoadingFiles) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _uploadFiles,
                icon: Icon(Icons.add, size: 18),
                label: Text('Add More Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        width: 400,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 48, color: Colors.orange),
                            const SizedBox(height: 16),
                            Text(
                              'Clear All Files',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Are you sure you want to remove all files? This will take effect after saving.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: AppColors.cardBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 100,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      setState(() => uploadedFiles.clear());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Clear',
                                        style:
                                            TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.delete_sweep, size: 18),
                label: Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilesLoading() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading files...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Container(
      height: 120,
      child: Center(
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
      ),
    );
  }

  Widget _buildEmptyFilesState() {
    return Container(
      height: 200,
      child: Center(
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
              'No teaching materials uploaded yet',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(12),
      itemCount: uploadedFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = uploadedFiles[index];
        final fileColor = _getFileColor(file.mimetype);

        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(file.mimetype),
                  color: fileColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            file.originalName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (file.isExisting)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Existing',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'New',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (file.isExisting) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: fileColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getFileExtLabel(file.mimetype),
                              style: TextStyle(
                                fontSize: 10,
                                color: fileColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (file.size > 0)
                          Text(
                            _formatFileSize(file.size),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  file.url.isNotEmpty ? Icons.open_in_new : Icons.download,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () => _previewFile(file),
                tooltip: file.url.isNotEmpty ? 'Open file' : 'Download file',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _removeFile(index),
                tooltip: 'Remove',
              ),
            ],
          ),
        );
      },
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

            // 編輯頁允許載入和選擇歷史日期
            DateTime initialDate = now;
            if (label.contains('Start') && startDateTime != null) {
              initialDate = startDateTime!;
            } else if (label.contains('End') && endDateTime != null) {
              initialDate = endDateTime!;
            }

            DateTime? date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              TimeOfDay initialTime = TimeOfDay.now();
              if (label.contains('Start') && startDateTime != null) {
                initialTime = TimeOfDay(
                    hour: startDateTime!.hour, minute: startDateTime!.minute);
              } else if (label.contains('End') && endDateTime != null) {
                initialTime = TimeOfDay(
                    hour: endDateTime!.hour, minute: endDateTime!.minute);
              }

              TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );

              if (time != null) {
                final dateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );

                if (label.contains('Start')) {
                  if (endDateTime != null && dateTime.isAfter(endDateTime!)) {
                    _showError('Start time must be earlier than end time');
                    return;
                  }
                }

                if (label.contains('End')) {
                  if (startDateTime != null && dateTime.isBefore(startDateTime!)) {
                    _showError('End time must be later than start time');
                    return;
                  }
                }

                controller.text = _formatDateTime(dateTime);
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
                DropdownMenuItem<String>(
                  enabled: false,
                  child: Divider(height: 1),
                ),
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

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final lat = double.tryParse(_latController.text.trim()) ?? 0.0;
      final long = double.tryParse(_longController.text.trim()) ?? 0.0;

      final request = CreateSchoolReq(
        _nameController.text.trim(),
        GpsLocation(lat, long),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New School',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
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

            Text('School Name *',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter school name',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('GPS Location (Optional)',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Latitude',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _longController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Longitude',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  height: 48,
                  child: TextButton(
                    onPressed:
                        isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _createSchool,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
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
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }
}