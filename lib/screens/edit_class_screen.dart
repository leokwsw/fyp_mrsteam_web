import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
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

/// Unified file item model for both existing and newly uploaded files.
class UploadedFileItem {
  final String originalName;
  final String displayName;
  final String path;
  final String? url;
  final int size;
  final String mimetype;
  final bool isExisting;

  /// Index in courseRes.files[] — only set for existing files.
  /// Used to call getCourseFileSignedUrl(courseId, fileIndex).
  final int? fileIndex;

  UploadedFileItem({
    required this.originalName,
    String? displayName,
    required this.path,
    this.url,
    required this.size,
    required this.mimetype,
    this.isExisting = false,
    this.fileIndex,
  }) : displayName = displayName ?? originalName;

  UploadedFileItem copyWith({String? displayName}) {
    return UploadedFileItem(
      originalName: originalName,
      displayName: displayName ?? this.displayName,
      path: path,
      url: url,
      size: size,
      mimetype: mimetype,
      isExisting: isExisting,
      fileIndex: fileIndex,
    );
  }
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

  List<UploadedFileItem> uploadedFiles = [];
  List<String> originalFilePaths = [];

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

      _classNameController.text = courseRes.name;
      _roomController.text = courseRes.room;
      _overviewController.text = courseRes.overview;
      selectedSchoolId = courseRes.schoolId;
      selectedTutorId = courseRes.tutorId;
      originalFilePaths = List<String>.from(courseRes.files ?? []);
      _subjectCodeController.text = courseRes.subjectShortName ?? '';

      if (courseRes.timestamps.isNotEmpty) {
        final firstTimestamp = courseRes.timestamps.first;
        startDateTime =
            DateTime.fromMillisecondsSinceEpoch(firstTimestamp.start.toInt());
        endDateTime =
            DateTime.fromMillisecondsSinceEpoch(firstTimestamp.end.toInt());
        _startTimeController.text = _formatDateTime(startDateTime!);
        _endTimeController.text = _formatDateTime(endDateTime!);
      }

      setState(() {
        schools = schoolsRes.items;
        tutors = tutorsRes.items;

        if (selectedSchoolId != null &&
            !schools.any((s) => s.id == selectedSchoolId)) {
          selectedSchoolId = null;
        }
        if (selectedTutorId != null &&
            !tutors.any((t) => t.id == selectedTutorId)) {
          selectedTutorId = null;
        }

        isLoading = false;
      });

      _loadExistingFiles();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  /// Two-phase load:
  /// Phase 1 — immediately show files with UUID-based names.
  /// Phase 2 — background: fetch signed URL via the CORRECT course endpoint
  ///            (GET /course/:id/files/:index/signed-url) to resolve the
  ///            original filename from the Content-Disposition header.
  Future<void> _loadExistingFiles() async {
    if (originalFilePaths.isEmpty) return;

    setState(() => isLoadingFiles = true);

    // Phase 1: build items with index tracked, show immediately
    final items = List.generate(originalFilePaths.length, (index) {
      final path = originalFilePaths[index];
      final serverFileName = path.split('/').last;
      return UploadedFileItem(
        originalName: serverFileName,
        path: path,
        size: 0,
        mimetype: _guessMimetype(serverFileName),
        isExisting: true,
        fileIndex: index, // ← critical: store position in courseRes.files[]
      );
    });

    if (mounted) {
      setState(() {
        uploadedFiles = List.from(items);
        isLoadingFiles = false;
      });
    }

    // Phase 2: resolve real filename from signed URL (background)
    for (int i = 0; i < items.length; i++) {
      if (!mounted) break;
      try {
        // ✅ Use course file signed URL endpoint, NOT /files/signed-url/:path
        final signedUrlRes = await _courseApi.getCourseFileSignedUrl(
          widget.classId,
          i,
          expiresIn: 3600,
        );
        final signedUrl = signedUrlRes.url;
        if (signedUrl.isNotEmpty) {
          final resolvedName =
              _extractFilenameFromUrl(signedUrl) ?? items[i].originalName;
          if (mounted) {
            setState(() {
              if (i < uploadedFiles.length) {
                uploadedFiles[i] =
                    uploadedFiles[i].copyWith(displayName: resolvedName);
              }
            });
          }
        }
      } catch (_) {
        // Keep UUID-based name as fallback — silent fail
      }
    }
  }

  /// Extract original filename from a presigned URL's
  /// response-content-disposition query parameter.
  String? _extractFilenameFromUrl(String signedUrl) {
    try {
      final uri = Uri.parse(signedUrl);
      final String? disposition =
          uri.queryParameters['response-content-disposition'] ??
              uri.queryParameters['Content-Disposition'];

      if (disposition != null) {
        final decoded = Uri.decodeComponent(disposition);
        final match = RegExp(
          r"""filename\*?=(?:UTF-8''|"?)([^";]+)"?""",
          caseSensitive: false,
        ).firstMatch(decoded);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.trim();
        }
      }
    } catch (_) {}
    return null;
  }

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
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'ppt', 'pptx', 'doc', 'docx',
          'xls', 'xlsx', 'png', 'jpg', 'jpeg'
        ],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => isUploading = true);

      for (var file in result.files) {
        try {
          MultipartFile multipartFile;

          if (file.bytes != null) {
            multipartFile = MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            );
          } else if (file.path != null) {
            multipartFile = await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            );
          } else {
            continue;
          }

          final request = UploadFileReq(multipartFile);
          final response = await _filesApi.uploadFile(request);

          setState(() {
            uploadedFiles.add(UploadedFileItem(
              originalName: response.file.originalName,
              displayName: response.file.originalName,
              path: response.file.path,
              url: response.file.url,
              size: response.file.size.toInt(),
              mimetype: response.file.mimetype,
              isExisting: false,
              // fileIndex is null for new files — they use response.file.url directly
            ));
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${file.name} uploaded successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Failed to upload ${file.name}: ${e.toString()}'),
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

  void _removeFile(int index) {
    final file = uploadedFiles[index];
    final fileName = file.displayName;

    if (file.isExisting) {
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
                const Icon(Icons.warning_amber_rounded,
                    size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
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
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
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
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Remove',
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
      setState(() => uploadedFiles.removeAt(index));
    }
  }

  void _triggerDownload(String url, String filename) {
    try {
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..setAttribute('target', '_blank');
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {
      html.window.open(url, '_blank');
    }
  }

  /// Download/preview a file.
  ///
  /// - New files  → use the URL returned from the upload response directly.
  /// - Existing files → fetch a fresh signed URL via
  ///   GET /course/:id/files/:index/signed-url  (avoids expiry issues).
  Future<void> _previewFile(UploadedFileItem file) async {
    final displayName = file.displayName;

    // New uploaded file: URL is already available from the upload response
    if (!file.isExisting && file.url != null && file.url!.isNotEmpty) {
      _triggerDownload(file.url!, displayName);
      return;
    }

    // Existing file: must have fileIndex to call the correct endpoint
    if (file.isExisting && file.fileIndex == null) {
      _showError('File index not available');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Getting file link...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 10),
        ),
      );
    }

    try {
      // ✅ Correct endpoint: /course/:id/files/:index/signed-url
      final signedUrlRes = await _courseApi.getCourseFileSignedUrl(
        widget.classId,
        file.fileIndex!,
        expiresIn: 3600,
      );

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final url = signedUrlRes.url;
      if (url.isNotEmpty) {
        _triggerDownload(url, displayName);
      } else {
        _showError('Could not get file download link');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError('Failed to get file link: ${e.toString()}');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
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

      final filePaths = uploadedFiles.map((f) => f.path).toList();

      final request = UpdateCourseReq(
        name: _classNameController.text.trim(),
        overview: _overviewController.text.trim(),
        room: _roomController.text.trim(),
        files: filePaths,
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
          const SnackBar(
            content: Text('Class updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/class');
      }
    } catch (e) {
      _showError('Failed to update class: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isSaving = false);
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
              const Icon(Icons.warning_amber_rounded,
                  size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
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
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
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
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Delete',
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
          const SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/class');
      }
    } catch (e) {
      _showError('Failed to delete class: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(currentRoute: '/class/edit'),
        body: const Center(child: CircularProgressIndicator()),
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading class data'),
              const SizedBox(height: 8),
              Text(errorMessage!,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
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
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Edit Class',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
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
                    label: 'Subject Code',
                    placeholder: 'e.g., MATH',
                    controller: _subjectCodeController,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Room',
                    placeholder: 'e.g., Room 301',
                    controller: _roomController,
                  ),
                  const SizedBox(height: 24),
                  _buildDateTimeField(
                      'Start Date and Time *', _startTimeController, (dt) {
                    setState(() => startDateTime = dt);
                  }),
                  const SizedBox(height: 24),
                  _buildDateTimeField(
                      'End Date and Time *', _endTimeController, (dt) {
                    setState(() => endDateTime = dt);
                  }),
                  const SizedBox(height: 24),
                  _buildSchoolDropdown(),
                  const SizedBox(height: 24),
                  _buildTutorDropdown(),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview / Notification Content',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
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
                  _buildFilesSection(),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed:
                              isSaving ? null : _showDeleteConfirmation,
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.white),
                          label: const Text('Delete',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
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
                                side: BorderSide(color: AppColors.inputBorder),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel',
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
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text('Save',
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

  // ═══════════════════════════════════════════════════════════════════════
  // Files Section
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Teaching Materials',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add More Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                            const Icon(Icons.warning_amber_rounded,
                                size: 48, color: Colors.orange),
                            const SizedBox(height: 16),
                            const Text(
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
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Cancel'),
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
                                              BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Clear',
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
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilesLoading() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text('Loading files...',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Uploading files...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilesState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No teaching materials uploaded yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
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
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: uploadedFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = uploadedFiles[index];
        final fileColor = _getFileColor(file.mimetype);

        return Container(
          padding: const EdgeInsets.all(12),
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
                child: Icon(_getFileIcon(file.mimetype),
                    color: fileColor, size: 24),
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
                            file.displayName,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (file.isExisting)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
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
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'New',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (file.isExisting) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
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
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  file.isExisting ? Icons.download : Icons.open_in_new,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () => _previewFile(file),
                tooltip: file.isExisting ? 'Download file' : 'Open file',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
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
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'YYYY/MM/DD HH:MM',
            hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5)),
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
            DateTime initialDate = DateTime.now();
            if (label.contains('Start') && startDateTime != null) {
              initialDate = startDateTime!;
            } else if (label.contains('End') && endDateTime != null) {
              initialDate = endDateTime!;
            }

            DateTime? date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (date != null && mounted) {
              TimeOfDay initialTime = TimeOfDay.now();
              if (label.contains('Start') && startDateTime != null) {
                initialTime = TimeOfDay(
                    hour: startDateTime!.hour,
                    minute: startDateTime!.minute);
              } else if (label.contains('End') && endDateTime != null) {
                initialTime = TimeOfDay(
                    hour: endDateTime!.hour,
                    minute: endDateTime!.minute);
              }

              TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (time != null) {
                final dateTime = DateTime(
                  date.year, date.month, date.day, time.hour, time.minute,
                );
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
        const Text('School *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                const DropdownMenuItem<String>(
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
        const Text('Tutor *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
              onChanged: (value) => setState(() => selectedTutorId = value),
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

// ═══════════════════════════════════════════════════════════════════════════
// Create School Dialog
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
                const Text(
                  'Create New School',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
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
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text('School Name *',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
            const Text('GPS Location (Optional)',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create School',
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