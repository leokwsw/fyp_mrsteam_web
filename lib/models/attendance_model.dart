class AttendanceRecord {
  final String tutorId;
  final String tutorName;
  final String classCode;
  final String className;
  final String school;
  final DateTime scheduledTime;
  final DateTime? checkInTime;
  final AttendanceStatus status;
  final String notes;

  AttendanceRecord({
    required this.tutorId,
    required this.tutorName,
    required this.classCode,
    required this.className,
    required this.school,
    required this.scheduledTime,
    this.checkInTime,
    required this.status,
    required this.notes,
  });
}

enum AttendanceStatus { present, absent, late }