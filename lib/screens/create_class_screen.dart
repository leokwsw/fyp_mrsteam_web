import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_course.dart';
import '../data/api/api_provider_school.dart';
import '../data/api/api_provider_users.dart';
import '../data/model/request/req_course.dart';
import '../data/model/response/res_school.dart';
import '../data/model/response/res_user.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({Key? key}) : super(key: key);

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
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

      final request = CreateCourseReq(
        _classNameController.text.trim(),
        _overviewController.text.trim(),
        _roomController.text.trim(),
        uploadedFiles,
        selectedSchoolId!,
        selectedTutorId!,
        [timestamp],
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
                                    // TODO: Implement file upload
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
                                  '${uploadedFiles.length} file(s) selected',
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () => context.go('/class'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            side: BorderSide(color: AppColors.inputBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: isSaving
                            ? ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : CustomButton(
                                text: 'Save',
                                onPressed: () => _saveClass(),
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
              items: schools.map((school) => DropdownMenuItem(
                value: school.id,
                child: Text(school.name),
              )).toList(),
              onChanged: (value) {
                setState(() => selectedSchoolId = value);
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