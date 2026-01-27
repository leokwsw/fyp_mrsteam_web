import 'package:json_annotation/json_annotation.dart';

part 'res_statistics.g.dart';

@JsonSerializable()
class StatisticsAttendanceSummaryRes {
  final num total;
  final num checked;
  final num unchecked;
  final num attendanceRate;

  StatisticsAttendanceSummaryRes(
    this.total,
    this.checked,
    this.unchecked,
    this.attendanceRate,
  );

  factory StatisticsAttendanceSummaryRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsAttendanceSummaryResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsAttendanceSummaryResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsAttendanceSummaryRes.fromJson(json);
}

@JsonSerializable()
class StatisticsAttendanceRes {
  final StatisticsAttendanceSummaryRes summary;
  final List<Map<String, dynamic>> byTutor;
  final List<Map<String, dynamic>> bySchool;

  StatisticsAttendanceRes(this.summary, this.byTutor, this.bySchool);

  factory StatisticsAttendanceRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsAttendanceResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsAttendanceResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsAttendanceRes.fromJson(json);
}

@JsonSerializable()
class StatisticsLeaveSummaryRes {
  final num total;
  final num pending;
  final num approved;
  final num rejected;
  final num approvalRate;

  StatisticsLeaveSummaryRes(
    this.total,
    this.pending,
    this.approved,
    this.rejected,
    this.approvalRate,
  );

  factory StatisticsLeaveSummaryRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsLeaveSummaryResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsLeaveSummaryResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsLeaveSummaryRes.fromJson(json);
}

@JsonSerializable()
class StatisticsLeaveRes {
  final StatisticsLeaveSummaryRes summary;
  final List<Map<String, dynamic>> byStatus;
  final List<Map<String, dynamic>> byTutor;

  StatisticsLeaveRes(this.summary, this.byStatus, this.byTutor);

  factory StatisticsLeaveRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsLeaveResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsLeaveResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsLeaveRes.fromJson(json);
}

@JsonSerializable()
class StatisticsCourseSummaryRes {
  final num total;

  StatisticsCourseSummaryRes(this.total);

  factory StatisticsCourseSummaryRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsCourseSummaryResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsCourseSummaryResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsCourseSummaryRes.fromJson(json);
}

@JsonSerializable()
class StatisticsCourseRes {
  final StatisticsCourseSummaryRes summary;
  final List<Map<String, dynamic>> byTutor;
  final List<Map<String, dynamic>> bySchool;

  StatisticsCourseRes(this.summary, this.byTutor, this.bySchool);

  factory StatisticsCourseRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsCourseResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsCourseResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsCourseRes.fromJson(json);
}

@JsonSerializable()
class StatisticsUsersRes {
  final num totalTutors;
  final num totalStaff;

  StatisticsUsersRes(this.totalTutors, this.totalStaff);

  factory StatisticsUsersRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsUsersResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsUsersResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsUsersRes.fromJson(json);
}

@JsonSerializable()
class StatisticsDashboardRes {
  final StatisticsAttendanceRes attendance;
  final StatisticsLeaveRes leave;
  final StatisticsCourseRes course;
  final StatisticsUsersRes users;

  StatisticsDashboardRes(this.attendance, this.leave, this.course, this.users);

  factory StatisticsDashboardRes.fromJson(Map<String, dynamic> json) =>
      _$StatisticsDashboardResFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsDashboardResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      StatisticsDashboardRes.fromJson(json);
}
