import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_button.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({Key? key}) : super(key: key);

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  String selectedTab = 'Upcoming';
  final TextEditingController _searchController = TextEditingController();
  String? selectedClassCode;
  String? selectedSchool;
  String? selectedTutor;
  String? selectedStatus;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/class'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Text(
                'Class',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // View Toggle Buttons
              Row(
                children: [
                  _buildViewButton('Calendar View', true),
                  const SizedBox(width: 16),
                  _buildViewButton('List View', false),
                ],
              ),
              const SizedBox(height: 24),

              // Tabs
              Row(
                children: [
                  _buildTab('Upcoming'),
                  const SizedBox(width: 32),
                  _buildTab('Past'),
                  const SizedBox(width: 32),
                  _buildTab('All'),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar - NOW FUNCTIONAL
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
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Filters and New Class Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildFilterDropdown(
                        'Class Code',
                        selectedClassCode,
                        ['C001', 'C002', 'C003', 'All'],
                        (value) => setState(() => selectedClassCode = value),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(
                        'School',
                        selectedSchool,
                        ['Tech Academy', 'Math Institute', 'Science College', 'All'],
                        (value) => setState(() => selectedSchool = value),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(
                        'Tutor',
                        selectedTutor,
                        ['Dr. Harper', 'Dr. Carter', 'Prof. Davies', 'All'],
                        (value) => setState(() => selectedTutor = value),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(
                        'Status',
                        selectedStatus,
                        ['Scheduled', 'Incomplete', 'Canceled', 'All'],
                        (value) => setState(() => selectedStatus = value),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 140,
                    child: CustomButton(
                      text: 'New Class',
                      onPressed: () {
                        context.push('/class/create');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Classes Table
              _buildClassesTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton(String text, bool isCalendar) {
    bool isActive = !isCalendar; // List view is active on this screen
    return GestureDetector(
      onTap: () {
        if (isCalendar) {
          context.go('/class');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text) {
    bool isActive = selectedTab == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = text;
        });
      },
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 60,
              color: AppColors.primary,
            ),
        ],
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

  Widget _buildClassesTable() {
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
                Expanded(
                  flex: 1,
                  child: Text('Class Code', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Class Name', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Schedule Time', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('School', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Tutor', style: _headerStyle()),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Status', style: _headerStyle()),
                ),
              ],
            ),
          ),
          // Table Rows
          _buildClassRow(
            'C001',
            'Introduction to Programming',
            '2024-09-01\n09:00 - 11:00',
            'Tech Academy',
            '[T001]\nDr. Harper',
            StatusType.success,
            'Scheduled',
          ),
          _buildClassRow(
            'C002',
            'Calculus I',
            '2024-09-01\n13:00 - 15:00',
            'Math Institute',
            '',
            StatusType.error,
            'Incomplete',
          ),
          _buildClassRow(
            'C003',
            'Organic Chemistry',
            '2024-09-01\n14:00 - 16:00',
            'Science College',
            '[T003]\nDr. Carter',
            StatusType.success,
            'Scheduled',
          ),
          _buildClassRow(
            'C004',
            'World History',
            '2024-09-01\n10:00 - 12:00',
            'Liberal Arts\nSchool',
            '[T006]\nProf. Davies',
            StatusType.success,
            'Scheduled',
          ),
          _buildClassRow(
            'C005',
            'Advanced Physics',
            '2024-09-01\n15:00 - 17:00',
            'Physics Institute',
            '[T008]\nDr. Foster',
            StatusType.error,
            'Canceled',
          ),
        ],
      ),
    );
  }

  Widget _buildClassRow(
    String code,
    String name,
    String time,
    String school,
    String tutor,
    StatusType statusType,
    String status,
  ) {
    // Apply search filter
    if (searchQuery.isNotEmpty &&
        !code.toLowerCase().contains(searchQuery) &&
        !name.toLowerCase().contains(searchQuery) &&
        !school.toLowerCase().contains(searchQuery) &&
        !tutor.toLowerCase().contains(searchQuery)) {
      return Container();
    }

    // Apply dropdown filters
    if (selectedClassCode != null &&
        selectedClassCode != 'All' &&
        code != selectedClassCode) {
      return Container();
    }

    if (selectedStatus != null &&
        selectedStatus != 'All' &&
        status != selectedStatus) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBorder.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(code, style: _cellStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text(name, style: _cellStyle()),
          ),
          Expanded(
            flex: 2,
            child: Text(
              time,
              style: _cellStyle().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              school,
              style: _cellStyle().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(tutor, style: _cellStyle()),
          ),
          Expanded(
            flex: 1,
            child: StatusBadge(text: status, type: statusType),
          ),
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