import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

/// Shared Class Details dialog used by both CalendarView and ListView.
///
/// [date] is optional — pass null when the caller already embeds the date
/// inside [time] or has no separate date to display (e.g. calendar view).
class ClassDetailsDialog extends StatelessWidget {
  final String courseId;
  final String className;
  final String schoolName;
  final String? date;
  final String time;
  final String tutorName;
  final String room;
  final String status;
  final String overview;

  const ClassDetailsDialog({
    super.key,
    required this.courseId,
    required this.className,
    required this.schoolName,
    this.date,
    required this.time,
    required this.tutorName,
    required this.room,
    required this.status,
    required this.overview,
  });

  Color _statusColor() {
    switch (status) {
      case 'Canceled':
        return const Color(0xFFB71C1C);
      case 'Completed':
        return Colors.green;
      default:
        return const Color(0xFF1E3A5F);
    }
  }

  Widget _detailRow(String label, String value) {
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
            value.isNotEmpty ? value : '-',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _statusRow() {
    final color = _statusColor();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            'Status:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Class Details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow('Class Name', className),
            const SizedBox(height: 16),
            _detailRow('School', schoolName),
            if (date != null) ...[
              const SizedBox(height: 16),
              _detailRow('Date', date!),
            ],
            const SizedBox(height: 16),
            _detailRow('Time', time),
            const SizedBox(height: 16),
            _detailRow('Tutor', tutorName),
            const SizedBox(height: 16),
            _detailRow('Room', room),
            const SizedBox(height: 16),
            _statusRow(),
            const SizedBox(height: 16),
            _detailRow('Overview', overview),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/class/edit/$courseId');
                    },
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
