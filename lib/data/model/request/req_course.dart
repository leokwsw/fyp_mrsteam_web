import 'package:json_annotation/json_annotation.dart';

part 'req_course.g.dart';

@JsonSerializable()
class CourseTimestampReq {
  final num start;
  final num end;

  CourseTimestampReq(this.start, this.end);

  factory CourseTimestampReq.fromJson(Map<String, dynamic> json) =>
      _$CourseTimestampReqFromJson(json);

  Map<String, dynamic> toJson() => _$CourseTimestampReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CourseTimestampReq.fromJson(json);
}

@JsonSerializable()
class CreateCourseReq {
  final String name;
  final String overview;
  final String room;
  final List<String> files;
  final String schoolId;
  final String tutorId;
  final List<CourseTimestampReq> timestamps;

  CreateCourseReq(
    this.name,
    this.overview,
    this.room,
    this.files,
    this.schoolId,
    this.tutorId,
    this.timestamps,
  );

  factory CreateCourseReq.fromJson(Map<String, dynamic> json) =>
      _$CreateCourseReqFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCourseReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CreateCourseReq.fromJson(json);
}

@JsonSerializable()
class UpdateCourseReq {
  final String? name;
  final String? overview;
  final String? room;
  final List<String>? files;
  final String? schoolId;
  final String? tutorId;
  final List<CourseTimestampReq>? timestamps;

  UpdateCourseReq({
    this.name,
    this.overview,
    this.room,
    this.files,
    this.schoolId,
    this.tutorId,
    this.timestamps,
  });

  factory UpdateCourseReq.fromJson(Map<String, dynamic> json) =>
      _$UpdateCourseReqFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCourseReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UpdateCourseReq.fromJson(json);
}
