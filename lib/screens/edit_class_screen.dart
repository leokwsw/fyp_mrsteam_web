import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_text_field.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_course.dart';
import '../data/api/api_provider_school.dart';
import '../data/api/api_provider_users.dart';
import '../data/model/request/req_course.dart';
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
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();

  final TextEditingController _classNameController = TextEditingController();
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
  List<String> uploadedFiles = [];

  CourseRes? existingCourse;

  bool isLoading = true;
  bool isSaving = false;
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

      // Populate form fields
      _classNameController.text = courseRes.name;
      _roomController.text = courseRes.room;
      _overviewController.text = courseRes.overview;
      selectedSchoolId = courseRes.schoolId;
      selectedTutorId = courseRes.tutorId;
      uploadedFiles = List<String>.from(courseRes.files ?? []);

      // Set timestamps if available
      if (courseRes.timestamps.isNotEmpty) {
        final firstTimestamp = courseRes.timestamps.first;
        startDateTime = DateTime.fromMillisecondsSinceEpoch(firstTimestamp.start.toInt());
        endDateTime = DateTime.fromMillisecondsSinceEpoch(firstTimestamp.end.toInt());

        _startTimeController.text = _formatDateTime(startDateTime!);
        _endTimeController.text = _formatDateTime(endDateTime!);
      }

      setState(() {
        schools = schoolsRes.items;
        tutors = tutorsRes.items;

        // Validate selected values exist in options
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
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
      builder: (context) => Dialog(
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
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteClass();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Delete', style: TextStyle(color: Colors.white)),
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
              Text(errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
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
                    placeholder: 'e.g., Math 101',
                    controller: _classNameController,
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

                  // Upload Teaching Materials
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Teaching Materials',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.inputBorder,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (uploadedFiles.isEmpty) ...[
                                Text(
                                  'Drag and drop files here or browse to upload PPTs, worksheets, and\nother materials for tutors.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('File upload not implemented yet')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.textPrimary,
                                    elevation: 0,
                                    side: BorderSide(color: AppColors.inputBorder),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text('Browse Files'),
                                ),
                              ] else ...[
                                Text(
                                  '${uploadedFiles.length} file(s) attached',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => uploadedFiles.clear());
                                  },
                                  child: Text('Clear Files'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          onPressed: isSaving ? null : _showDeleteConfirmation,
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.white),
                          label: Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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
              lastDate: DateTime.now().add(Duration(days: 365 * 2)),
            );
            if (date != null) {
              TimeOfDay initialTime = TimeOfDay.now();
              if (label.contains('Start') && startDateTime != null) {
                initialTime = TimeOfDay(hour: startDateTime!.hour, minute: startDateTime!.minute);
              } else if (label.contains('End') && endDateTime != null) {
                initialTime = TimeOfDay(hour: endDateTime!.hour, minute: endDateTime!.minute);
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
              hint: Text('Select School', style: TextStyle(color: AppColors.textSecondary)),
              isExpanded: true,
              icon: Icon(Icons.unfold_more, color: AppColors.textSecondary),
              items: [
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
              items: tutors.map((tutor) => DropdownMenuItem(
                value: tutor.id,
                child: Text(tutor.name),
              )).toList(),
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

  const CreateSchoolDialog({Key? key, required this.onSchoolCreated}) : super(key: key);

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
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
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

            Text('School Name *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter school name',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('GPS Location (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Latitude',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _longController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Longitude',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.inputBorder),
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
                    onPressed: isSaving ? null : () => Navigator.of(context).pop(),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }
}