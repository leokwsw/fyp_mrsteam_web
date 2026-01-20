import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({Key? key}) : super(key: key);

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final TextEditingController _classCodeController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _notificationController = TextEditingController();

  String? selectedSchool;
  String? selectedTutor;

  @override
  Widget build(BuildContext context) {
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
                  // Page Title
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

                  // Class Code
                  CustomTextField(
                    label: 'Class Code',
                    placeholder: 'C001',
                    controller: _classCodeController,
                  ),
                  const SizedBox(height: 24),

                  // Class Name
                  CustomTextField(
                    label: 'Class Name',
                    placeholder: 'e.g., Math 101',
                    controller: _classNameController,
                  ),
                  const SizedBox(height: 24),

                  // Start Date and Time
                  _buildDateTimeField('Start Date and Time', _startTimeController),
                  const SizedBox(height: 24),

                  // End Date and Time
                  _buildDateTimeField('End Date and Time', _endTimeController),
                  const SizedBox(height: 24),

                  // School Dropdown
                  _buildDropdown('School', 'Select School', selectedSchool, (value) {
                    setState(() {
                      selectedSchool = value;
                    });
                  }),
                  const SizedBox(height: 24),

                  // Tutor Dropdown
                  _buildDropdown('Tutor', 'Select Tutor', selectedTutor, (value) {
                    setState(() {
                      selectedTutor = value;
                    });
                  }),
                  const SizedBox(height: 24),

                  // Notification Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Content',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notificationController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Customize the content for automated notifications sent to tutors regarding class schedules, material updates, etc.',
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
                                  // Handle file upload
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
                          onPressed: () => context.pop(),
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
                        child: CustomButton(
                          text: 'Save',
                          onPressed: () {
                            // Handle save
                            context.pop();
                          },
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

  Widget _buildDateTimeField(String label, TextEditingController controller) {
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
            // Show date/time picker
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
                controller.text = 
                    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              }
            }
          },
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String hint, String? value, Function(String?) onChanged) {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(color: AppColors.textSecondary)),
              isExpanded: true,
              icon: Icon(Icons.unfold_more, color: AppColors.textSecondary),
              items: ['Option 1', 'Option 2', 'Option 3']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    _classNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _notificationController.dispose();
    super.dispose();
  }
}