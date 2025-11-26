import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button.dart';
import 'create_class_screen.dart';
import 'class_list_screen.dart';

class ClassCalendarScreen extends StatefulWidget {
  const ClassCalendarScreen({Key? key}) : super(key: key);

  @override
  State<ClassCalendarScreen> createState() => _ClassCalendarScreenState();
}

class _ClassCalendarScreenState extends State<ClassCalendarScreen> {
  DateTime selectedMonth = DateTime(2024, 9, 1); // September 2024
  String selectedTab = 'Upcoming';
  String? selectedClassCode;
  String? selectedSchool;
  String? selectedTutor;
  String? selectedStatus;

  // Sample class data with more details
  final Map<int, List<CalendarClass>> allClassEvents = {
    3: [
      CalendarClass(
        schoolName: 'Northwood High',
        time: '13:00 - 14:30',
        classCode: 'ENG-101-A',
        color: Colors.red,
        tutor: 'Dr. Sarah Johnson',
        status: 'Canceled',
        location: 'Room 301',
        notes: 'Class canceled due to teacher illness',
      ),
    ],
    8: [
      CalendarClass(
        schoolName: 'Oakridge Academy',
        time: '09:30 - 11:00',
        classCode: 'MATH-202-B',
        color: Colors.green,
        tutor: 'Dr. Harper',
        status: 'Scheduled',
        location: 'Room 205',
        notes: 'Regular class session',
      ),
    ],
    15: [
      CalendarClass(
        schoolName: 'Riverside Prep',
        time: '10:00 - 11:30',
        classCode: 'SCI-105-C',
        color: Colors.green,
        tutor: 'Dr. Carter',
        status: 'Scheduled',
        location: 'Lab Building A',
        notes: 'Science lab session',
      ),
      CalendarClass(
        schoolName: 'Northwood High',
        time: '13:00 - 14:30',
        classCode: 'ENG-101-A',
        color: Colors.red,
        tutor: 'Dr. Sarah Johnson',
        status: 'Canceled',
        location: 'Room 301',
        notes: 'Rescheduled for next week',
      ),
    ],
  };

  // Get filtered events based on selected filters
  Map<int, List<CalendarClass>> get filteredClassEvents {
    Map<int, List<CalendarClass>> filtered = {};
    
    allClassEvents.forEach((day, events) {
      List<CalendarClass> filteredEvents = events.where((event) {
        bool matchesClassCode = selectedClassCode == null || 
            selectedClassCode == 'All' || 
            event.classCode == selectedClassCode;
        
        bool matchesSchool = selectedSchool == null || 
            selectedSchool == 'All' || 
            event.schoolName.contains(selectedSchool!);
        
        bool matchesTutor = selectedTutor == null || 
            selectedTutor == 'All' || 
            event.tutor == selectedTutor;
        
        bool matchesStatus = selectedStatus == null || 
            selectedStatus == 'All' || 
            event.status == selectedStatus;
        
        return matchesClassCode && matchesSchool && matchesTutor && matchesStatus;
      }).toList();
      
      if (filteredEvents.isNotEmpty) {
        filtered[day] = filteredEvents;
      }
    });
    
    return filtered;
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  void _showEventDetails(CalendarClass event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    'Class Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Class Code
              _buildDetailRow('Class Code', event.classCode),
              const SizedBox(height: 16),
              
              // School
              _buildDetailRow('School', event.schoolName),
              const SizedBox(height: 16),
              
              // Time
              _buildDetailRow('Time', event.time),
              const SizedBox(height: 16),
              
              // Tutor
              _buildDetailRow('Tutor', event.tutor),
              const SizedBox(height: 16),
              
              // Location
              _buildDetailRow('Location', event.location),
              const SizedBox(height: 16),
              
              // Status
              Row(
                children: [
                  Text(
                    'Status: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: event.color),
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: event.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Notes
              _buildDetailRow('Notes', event.notes),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to edit screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Edit Class'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

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
              const SizedBox(height: 32),

              // Month Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month navigation
                  Row(
                    children: [
                      Text(
                        _getMonthName(selectedMonth.month),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ],
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
                        ['All', 'ENG-101-A', 'MATH-202-B', 'SCI-105-C'],
                        (value) => setState(() => selectedClassCode = value),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(
                        'School',
                        selectedSchool,
                        ['All', 'Northwood High', 'Oakridge Academy', 'Riverside Prep'],
                        (value) => setState(() => selectedSchool = value),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(
                        'Tutor',
                        selectedTutor,
                        ['All', 'Dr. Harper', 'Dr. Carter', 'Dr. Sarah Johnson'],
                        (value) => setState(() => selectedTutor = value),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(
                        'Status',
                        selectedStatus,
                        ['All', 'Scheduled', 'Canceled', 'Completed'],
                        (value) => setState(() => selectedStatus = value),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 140,
                    child: CustomButton(
                      text: 'New Class',
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                CreateClassScreen(),
                            transitionsBuilder:
                                (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: Duration(milliseconds: 200),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calendar
              _buildCalendar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewButton(String text, bool isCalendar) {
    bool isActive = isCalendar;
    return GestureDetector(
      onTap: () {
        if (!isCalendar) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ClassListScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: Duration(milliseconds: 200),
            ),
          );
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

  Widget _buildCalendar() {
    // Get first day of month and number of days
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Get previous month's last days to fill the grid
    final prevMonthLastDay = DateTime(selectedMonth.year, selectedMonth.month, 0).day;
    final prevMonthDaysToShow = startWeekday;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Calendar Header (Days of Week)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: Row(
              children: [
                _buildDayHeader('SUN'),
                _buildDayHeader('MON'),
                _buildDayHeader('TUE'),
                _buildDayHeader('WED'),
                _buildDayHeader('THU'),
                _buildDayHeader('FRI'),
                _buildDayHeader('SAT'),
              ],
            ),
          ),

          // Calendar Grid
          _buildCalendarGrid(
            daysInMonth,
            startWeekday,
            prevMonthLastDay,
            prevMonthDaysToShow,
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String day) {
    return Expanded(
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(
    int daysInMonth,
    int startWeekday,
    int prevMonthLastDay,
    int prevMonthDaysToShow,
  ) {
    List<Widget> weeks = [];
    int currentDay = 1;
    int nextMonthDay = 1;

    // Calculate total rows needed (usually 5-6 weeks)
    int totalCells = daysInMonth + startWeekday;
    int numWeeks = (totalCells / 7).ceil();

    for (int week = 0; week < numWeeks; week++) {
      List<Widget> days = [];

      for (int weekday = 0; weekday < 7; weekday++) {
        int cellIndex = week * 7 + weekday;

        if (cellIndex < startWeekday) {
          // Previous month's days
          int prevDay = prevMonthLastDay - prevMonthDaysToShow + cellIndex + 1;
          days.add(_buildCalendarCell(prevDay, true, []));
        } else if (currentDay <= daysInMonth) {
          // Current month's days
          bool isToday = currentDay == 5; // Highlighting day 5 in the design
          List<CalendarClass> events = filteredClassEvents[currentDay] ?? [];
          days.add(_buildCalendarCell(currentDay, false, events, isToday: isToday));
          currentDay++;
        } else {
          // Next month's days
          days.add(_buildCalendarCell(nextMonthDay, true, []));
          nextMonthDay++;
        }
      }

      weeks.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: days,
        ),
      );
    }

    return Column(children: weeks);
  }

  Widget _buildCalendarCell(
    int day,
    bool isOtherMonth,
    List<CalendarClass> events, {
    bool isToday = false,
  }) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isToday ? Color(0xFFD6E4F5) : Colors.white,
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
        child: Stack(
          children: [
            // Day number
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: isToday
                    ? BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? Colors.white
                          : isOtherMonth
                              ? AppColors.textSecondary.withOpacity(0.4)
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Events - ALL SAME SIZE WITH CLICK HANDLER
            if (events.isNotEmpty)
              Positioned(
                top: 36,
                left: 4,
                right: 4,
                bottom: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...events.take(2).map((event) => _buildEventCard(event)),
                    if (events.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${events.length - 2} more',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(CalendarClass event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        height: 32, // FIXED HEIGHT FOR ALL EVENTS
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: event.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border(
            left: BorderSide(color: event.color, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                event.schoolName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: event.color,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Flexible(
              child: Text(
                event.time,
                style: TextStyle(
                  fontSize: 9,
                  color: event.color,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class CalendarClass {
  final String schoolName;
  final String time;
  final String classCode;
  final Color color;
  final String tutor;
  final String status;
  final String location;
  final String notes;

  CalendarClass({
    required this.schoolName,
    required this.time,
    required this.classCode,
    required this.color,
    required this.tutor,
    required this.status,
    required this.location,
    required this.notes,
  });
}