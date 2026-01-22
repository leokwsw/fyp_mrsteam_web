import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_button.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedRole;
  String? selectedStatus;
  String searchQuery = '';

  final List<Map<String, dynamic>> users = [
    {'userId': 'T001', 'name': 'Ethan Walker', 'email': 'ethan.walker@email.com', 'role': 'Tutor', 'status': 'Inactive'},
    {'userId': 'T002', 'name': 'Sophia Carter', 'email': 'sophia.carter@email.com', 'role': 'Tutor', 'status': 'Active'},
    {'userId': 'A001', 'name': 'Liam Harper', 'email': 'liam.harper@email.com', 'role': 'Admin', 'status': 'Active'},
    {'userId': 'T003', 'name': 'Olivia Foster', 'email': 'olivia.foster@email.com', 'role': 'Tutor', 'status': 'Active'},
    {'userId': 'T004', 'name': 'Noah Brooks', 'email': 'noah.brooks@email.com', 'role': 'Tutor', 'status': 'Active'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/account'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and New User Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account Management',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: CustomButton(
                      text: 'New User',
                      onPressed: () {
                        context.go('/account/new');
                      },
                    ),
                  ),
                ],
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
                  hintText: 'Search User',
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
                    'Account Role',
                    selectedRole,
                    ['All', 'Admin', 'Tutor'],
                    (value) => setState(() => selectedRole = value),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown(
                    'Status',
                    selectedStatus,
                    ['All', 'Active', 'Inactive'],
                    (value) => setState(() => selectedStatus = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Users Table
              _buildUsersTable(),
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

  Widget _buildUsersTable() {
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
                Expanded(flex: 2, child: Text('User ID', style: _headerStyle())),
                Expanded(flex: 3, child: Text('Name', style: _headerStyle())),
                Expanded(flex: 4, child: Text('Email', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Account Role', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Status', style: _headerStyle())),
              ],
            ),
          ),
          // Table Rows
          ...users.where((user) {
            bool matchesSearch = searchQuery.isEmpty ||
                user['name'].toLowerCase().contains(searchQuery) ||
                user['email'].toLowerCase().contains(searchQuery) ||
                user['userId'].toLowerCase().contains(searchQuery);
            
            bool matchesRole = selectedRole == null || 
                selectedRole == 'All' || 
                user['role'] == selectedRole;
            
            bool matchesStatus = selectedStatus == null || 
                selectedStatus == 'All' || 
                user['status'] == selectedStatus;
            
            return matchesSearch && matchesRole && matchesStatus;
          }).map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    return InkWell(
      onTap: () {
        context.go('/account/user/${user['userId']}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(user['userId'], style: _cellStyle()),
            ),
            Expanded(
              flex: 3,
              child: Text(user['name'], style: _cellStyle()),
            ),
            Expanded(
              flex: 4,
              child: Text(
                user['email'],
                style: _cellStyle().copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(user['role'], style: _cellStyle()),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  text: user['status'],
                  type: user['status'] == 'Active' ? StatusType.success : StatusType.error,
                ),
              ),
            ),
          ],
        ),
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