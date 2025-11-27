import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/status_badge.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedTutor;
  String? selectedClass;
  String? selectedSchool;
  String? selectedStatus;
  String searchQuery = '';

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
              // Page Title
              Text(
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
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Filters
              Row(
                children: [
                  _buildFilterDropdown(
                    'Tutor',
                    selectedTutor,
                    ['All', 'Sophia Bennett', 'Ethan Carter', 'Olivia Harper'],
                    (value) => setState(() => selectedTutor = value),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown(
                    'Class',
                    selectedClass,
                    ['All', 'Mathematics 101', 'English Literature', 'Science Fundamentals'],
                    (value) => setState(() => selectedClass = value),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown(
                    'School',
                    selectedSchool,
                    ['All', 'Northwood High', 'Southside Elementary', 'Westview Middle'],
                    (value) => setState(() => selectedSchool = value),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown(
                    'Status',
                    selectedStatus,
                    ['All', 'Present', 'Absent', 'Late'],
                    (value) => setState(() => selectedStatus = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Attendance Table
              _buildAttendanceTable(),
              const SizedBox(height: 24),

              // Export Button
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exporting attendance records...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
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

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          icon: Container(),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
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
                Expanded(flex: 3, child: Text('Notes', style: _headerStyle())),
              ],
            ),
          ),
          // Table Rows
          _buildRow('[T001]\nSophia Bennett', '[C001]\nMathematics 101', 'Northwood\nHigh', '2024-07-20\n09:00 - 10:00', '2024-07-20\n09:00', StatusType.success, 'Present', 'No issues\nreported'),
          _buildRow('[T002]\nEthan Carter', '[C002]\nEnglish Literature', 'Southside\nElementary', '2024-07-20\n08:30 - 09:30', '2024-07-20\n08:30', StatusType.error, 'Absent', 'Sick leave'),
          _buildRow('[T003]\nOlivia Harper', '[C003]\nScience\nFundamentals', 'Westview\nMiddle', '2024-07-21\n09:00 - 10:00', '2024-07-21\n09:10', StatusType.error, 'Late', 'Arrived 10\nminutes late'),
          _buildRow('[T004]\nNoah Foster', '[C004]\nHistory Basics', 'Eastside\nAcademy', '2024-07-21\n08:00 - 09:00', '2024-07-21\n08:00', StatusType.success, 'Present', 'No issues\nreported'),
          _buildRow('[T005]\nAva Morgan', '[C005]\nMathematics 101', 'Northwood\nHigh', '2024-07-22\n08:00 - 09:00', '2024-07-22\n08:00', StatusType.success, 'Present', 'No issues\nreported'),
          _buildRow('[T006]\nLiam Hayes', '[C006]\nEnglish Literature', 'Southside\nElementary', '2024-07-22\n08:30 - 09:30', '2024-07-22\n08:30', StatusType.error, 'Absent', 'Personal\nleave'),
          _buildRow('[T007]\nChloe Reed', '[C007]\nScience\nFundamentals', 'Westview\nMiddle', '2024-07-23\n08:00 - 09:00', '2024-07-23\n08:00', StatusType.success, 'Present', 'No issues\nreported'),
          _buildRow('[T008]\nJackson Cole', '[C008]\nHistory Basics', 'Eastside\nAcademy', '2024-07-23\n08:00 - 09:00', '2024-07-23\n08:00', StatusType.success, 'Present', 'No issues\nreported'),
          _buildRow('[T009]\nGrace Turner', '[C009]\nMathematics 101', 'Northwood\nHigh', '2024-07-24\n08:00 - 09:00', '2024-07-24\n08:00', StatusType.success, 'Present', 'No issues\nreported'),
          _buildRow('[T010]\nOwen Brooks', '[C010]\nEnglish Literature', 'Southside\nElementary', '2024-07-24\n08:00 - 09:00', '2024-07-24\n08:00', StatusType.success, 'Present', 'No issues\nreported'),
        ],
      ),
    );
  }

  Widget _buildRow(String tutor, String classInfo, String school, String scheduled, String checkIn, StatusType statusType, String status, String notes) {
    // Apply search filter
    if (searchQuery.isNotEmpty &&
        !tutor.toLowerCase().contains(searchQuery) &&
        !classInfo.toLowerCase().contains(searchQuery) &&
        !school.toLowerCase().contains(searchQuery)) {
      return Container();
    }

    // Apply dropdown filters
    if (selectedStatus != null &&
        selectedStatus != 'All' &&
        status != selectedStatus) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(tutor, style: _cellStyle())),
          Expanded(flex: 2, child: Text(classInfo, style: _cellStyle().copyWith(color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text(school, style: _cellStyle().copyWith(color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text(scheduled, style: _cellStyle())),
          Expanded(flex: 2, child: Text(checkIn, style: _cellStyle())),
          Expanded(flex: 2, child: StatusBadge(text: status, type: statusType)),
          Expanded(flex: 3, child: Text(notes, style: _cellStyle().copyWith(fontSize: 12))),
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