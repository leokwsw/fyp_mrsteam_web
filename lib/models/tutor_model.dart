class TutorModel {
  final String id;
  final String name;
  final String subject;
  final DateTime? lastCheckIn;
  final AttendanceStatus status;

  TutorModel({
    required this.id,
    required this.name,
    required this.subject,
    this.lastCheckIn,
    required this.status,
  });
}

enum AttendanceStatus { present, absent, late }