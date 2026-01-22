import 'package:fyp_mrsteam_web/data/model/response/res_course.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_school.dart';
import 'package:json_annotation/json_annotation.dart';

part 'res_attendance.g.dart';

@JsonSerializable()
class AttendanceRes {
  @JsonKey(name: '_id')
  final String? id;
  final String courseId;
  final CourseTimestampRes timestamp;
  @JsonKey(name: 'timestamp_index')
  final num timestampIndex;
  final bool checked;
  final String tutorId;
  final String schoolId;
  final String? photoUrl;
  final String? checkInTime;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  AttendanceRes(
    this.courseId,
    this.timestamp,
    this.timestampIndex,
    this.checked,
    this.tutorId,
    this.schoolId, {
    this.id,
    this.photoUrl,
    this.checkInTime,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRes.fromJson(Map<String, dynamic> json) =>
      _$AttendanceResFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      AttendanceRes.fromJson(json);
}

@JsonSerializable()
class AttendanceListRes {
  final List<AttendanceRes> items;
  final int total;
  final int page;
  final int limit;
  final int pages;
  final Map<String, CourseRes>? courses;
  final Map<String, SchoolRes>? schools;

  AttendanceListRes(
    this.items,
    this.total,
    this.page,
    this.limit,
    this.pages, {
    this.courses,
    this.schools,
  });

  factory AttendanceListRes.fromJson(Map<String, dynamic> json) =>
      _$AttendanceListResFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceListResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      AttendanceListRes.fromJson(json);
}
