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
  @JsonKey(readValue: AttendanceRes._readStatus)
  final String status;
  final String tutorId;
  final String schoolId;
  final String? photoUrl;
  @JsonKey(readValue: AttendanceRes._readArrivedTime)
  final String? arrivedTime;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  AttendanceRes(
    this.courseId,
    this.timestamp,
    this.timestampIndex,
    this.status,
    this.tutorId,
    this.schoolId, {
    this.arrivedTime,
    this.id,
    this.photoUrl,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  /// Backward-compatible `checked` field (checked in and arrived/late).
  bool get checked => status == 'arrived' || status == 'late';

  /// Backward-compatible `checkInTime` field name.
  String? get checkInTime => arrivedTime;

  static Object? _readStatus(Map<dynamic, dynamic> json, String key) {
    final v = json['status'];
    if (v is String && v.isNotEmpty) return v;
    if (json['checked'] == true) return 'arrived';
    if (json['checked'] == false) return 'absent';
    return 'pending';
  }

  static Object? _readArrivedTime(Map<dynamic, dynamic> json, String key) {
    return json['arrivedTime'] ?? json['checkInTime'];
  }

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
