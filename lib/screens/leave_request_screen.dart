import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../widgets/app_bar_widget.dart';
import '../core/config/get_it.dart';
import '../data/api/api_provider_leave.dart';
import '../data/api/api_provider_users.dart';
import '../data/model/request/req_leave.dart';
import '../data/model/response/res_leave.dart';
import '../data/model/response/res_user.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({Key? key}) : super(key: key);

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final ApiProviderLeave _leaveApi = getIt<ApiProviderLeave>();
  final ApiProviderUsers _usersApi = getIt<ApiProviderUsers>();

  List<LeaveRes> allLeaves = [];
  Map<String, UserResponse> tutorsMap = {};

  bool isLoading = true;
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
        _leaveApi.getLeaves(),
        _usersApi.getUsers(role: 'tutor'),
      ]);

      final leavesRes = futures[0] as LeaveListRes;
      final tutorsRes = futures[1] as dynamic;

      // Build tutor lookup map
      for (var tutor in tutorsRes.items) {
        if (tutor.id != null) {
          tutorsMap[tutor.id!] = tutor;
        }
      }

      setState(() {
        allLeaves = leavesRes.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<LeaveRes> get pendingLeaves {
    return allLeaves.where((leave) => leave.status.toLowerCase() == 'pending').toList();
  }

  List<LeaveRes> get historyLeaves {
    return allLeaves.where((leave) => 
      leave.status.toLowerCase() == 'approved' || 
      leave.status.toLowerCase() == 'rejected'
    ).toList();
  }

  String _getTutorName(String tutorId) {
    return tutorsMap[tutorId]?.name ?? 'Unknown Tutor';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _approveLeave(LeaveRes leave) async {
    try {
      final request = ApproveLeaveReq('approved');
      await _leaveApi.approveLeave(leave.id!, request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve leave request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(LeaveRes leave) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
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
                      'Reject Leave Request',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Leave Info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Tutor', _getTutorName(leave.tutorId)),
                      const SizedBox(height: 8),
                      _buildInfoRow('Date', _formatDate(leave.startDate)),
                      const SizedBox(height: 8),
                      _buildInfoRow('Leave Reason', leave.reason),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Rejection Reason Input
                Text(
                  'Rejection Reason *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter the reason for rejection...',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
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
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter a rejection reason'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final request = ApproveLeaveReq(
                              'rejected',
                              rejectionReason: reasonController.text.trim(),
                            );
                            await _leaveApi.approveLeave(leave.id!, request);

                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Leave request rejected'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to reject: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Reject', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/leave'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Leave Requests',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Content
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
                        Text('Error loading leave requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: Text('Retry')),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending Requests Section
                    Text(
                      'Pending Requests',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _buildPendingRequestsTable(),
                    const SizedBox(height: 40),

                    // Request History Section
                    Text(
                      'Request History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _buildHistoryTable(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequestsTable() {
    final pending = pendingLeaves;

    if (pending.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'No pending requests',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildHeaderCell('Tutor')),
                Expanded(flex: 2, child: _buildHeaderCell('Date')),
                Expanded(flex: 3, child: _buildHeaderCell('Leave Reason')),
                Expanded(flex: 2, child: _buildHeaderCell('Actions')),
              ],
            ),
          ),
          // Table Body
          ...pending.map((leave) => _buildPendingRow(leave)),
        ],
      ),
    );
  }

  Widget _buildPendingRow(LeaveRes leave) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getTutorName(leave.tutorId),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(leave.startDate),
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              leave.reason,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _approveLeave(leave),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text('Accept', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(leave),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF5350),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text('Reject', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    final history = historyLeaves;

    if (history.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No request history',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildHeaderCell('Tutor')),
                Expanded(flex: 2, child: _buildHeaderCell('Date')),
                Expanded(flex: 3, child: _buildHeaderCell('Leave Reason')),
                Expanded(flex: 2, child: _buildHeaderCell('Status')),
                Expanded(flex: 3, child: _buildHeaderCell('Reject Reason')),
              ],
            ),
          ),
          // Table Body
          ...history.map((leave) => _buildHistoryRow(leave)),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(LeaveRes leave) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getTutorName(leave.tutorId),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(leave.startDate),
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              leave.reason,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(leave.status),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              leave.rejectionReason ?? '-',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayText;
    
    switch (status.toLowerCase()) {
      case 'approved':
        color = Color(0xFF4CAF50);
        displayText = 'Approved';
        break;
      case 'rejected':
        color = Color(0xFFEF5350);
        displayText = 'Rejected';
        break;
      default:
        color = Color(0xFF1E3A5F);
        displayText = status;
    }

    return Container(
      width:80,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      textAlign: TextAlign.center,
      ),
    );
  }
}