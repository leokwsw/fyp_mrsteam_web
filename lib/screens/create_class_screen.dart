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
import '../data/model/request/req_school.dart';
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
    // Validate
    if (_nameController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter school name');
      return;
    }

    final lat = double.tryParse(_latController.text.trim());
    final long = double.tryParse(_longController.text.trim());

    if (lat == null || long == null) {
      setState(() => errorMessage = 'Please enter valid GPS coordinates');
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
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

            // GPS Coordinates
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
                    controller: _latController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isSaving ? null : _createSchool,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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