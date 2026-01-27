class ClassModel {
  final String code;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String school;
  final String tutor;
  final String tutorId;
  final ClassStatus status;

  ClassModel({
    required this.code,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.school,
    required this.tutor,
    required this.tutorId,
    required this.status,
  });
}

enum ClassStatus { ongoing, upcoming, canceled, scheduled, incomplete }