import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/status_badge.dart';
import '../widgets/custom_button.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_users.dart';
import '../data/model/response/res_user.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();
  
  String? selectedRole;
  String? selectedStatus;
  String searchQuery = '';
  
  List<UserResponse> users = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _usersApi.getUsers(
        search: searchQuery.isNotEmpty ? searchQuery : null,
        role: (selectedRole != null && selectedRole != 'All') ? selectedRole!.toLowerCase() : null,
        isActive: (selectedStatus != null && selectedStatus != 'All') 
            ? (selectedStatus == 'Active' ? 'true' : 'false') 
            : null,
      );
      
      setState(() {
        users = response.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

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
                  // Debounce search - reload after user stops typing
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (searchQuery == value.toLowerCase()) {
                      _loadUsers();
                    }
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
                    (value) {
                      setState(() => selectedRole = value);
                      _loadUsers();
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildFilterDropdown(
                    'Status',
                    selectedStatus,
                    ['All', 'Active', 'Inactive'],
                    (value) {
                      setState(() => selectedStatus = value);
                      _loadUsers();
                    },
                  ),
                  const Spacer(),
                  // Refresh Button
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _loadUsers,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content: Loading, Error, or Table
              if (isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        CustomButton(text: 'Retry', onPressed: _loadUsers),
                      ],
                    ),
                  ),
                )
              else
                _buildUsersTable(),
            ],
          ),
        ),
      ),
    );
  }

  Theme _buildDropdownTheme({required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: const Color(0xFFF5F5F5),
        focusColor: Colors.transparent,
      ),
      child: child,
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: _buildDropdownTheme(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              hint: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item, style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('No users found', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

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
                Expanded(flex: 2, child: Text('Username', style: _headerStyle())),
                Expanded(flex: 3, child: Text('Name', style: _headerStyle())),
                Expanded(flex: 4, child: Text('Email', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Account Role', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Status', style: _headerStyle())),
              ],
            ),
          ),
          // Table Rows
          ...users.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildUserRow(UserResponse user) {
    final bool isActive = user.isActive ?? false;
    final String status = isActive ? 'Active' : 'Inactive';
    final String displayRole = _capitalizeFirst(user.role ?? 'Unknown');
    
    return InkWell(
      onTap: () {
        context.go('/account/user/${user.id}');
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
              child: Text(user.username ?? user.id ?? '-', style: _cellStyle()),
            ),
            Expanded(
              flex: 3,
              child: Text(user.name, style: _cellStyle()),
            ),
            Expanded(
              flex: 4,
              child: Text(
                user.email,
                style: _cellStyle().copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(displayRole, style: _cellStyle()),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  text: status,
                  type: isActive ? StatusType.success : StatusType.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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