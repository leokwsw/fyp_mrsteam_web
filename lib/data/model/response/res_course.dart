import 'package:json_annotation/json_annotation.dart';
part 'res_course.g.dart';

@JsonSerializable()
class CourseTimestampRes {
  final num start;
  final num end;

  CourseTimestampRes(this.start, this.end);

  factory CourseTimestampRes.fromJson(Map<String, dynamic> json) =>
      _$CourseTimestampResFromJson(json);

  Map<String, dynamic> toJson() => _$CourseTimestampResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CourseTimestampRes.fromJson(json);
}

@JsonSerializable()
class CourseRes {
  @JsonKey(name: '_id')
  final String? id;
  final String name;
  final String overview;
  final String room;
  final List<String> files;
  final String schoolId;
  final String tutorId;
  final List<CourseTimestampRes> timestamps;
  final String? subjectShortName;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  CourseRes(
    this.name,
    this.overview,
    this.room,
    this.files,
    this.schoolId,
    this.tutorId,
    this.timestamps, {
    this.id,
    this.subjectShortName,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseRes.fromJson(Map<String, dynamic> json) =>
      _$CourseResFromJson(json);

  Map<String, dynamic> toJson() => _$CourseResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => CourseRes.fromJson(json);
}

@JsonSerializable()
class CourseListRes {
  final List<CourseRes> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  CourseListRes(this.items, this.total, this.page, this.limit, this.pages);

  factory CourseListRes.fromJson(Map<String, dynamic> json) =>
      _$CourseListResFromJson(json);

  Map<String, dynamic> toJson() => _$CourseListResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CourseListRes.fromJson(json);
}

/// 課程文件響應
/// 注意：後端返回 files 為 List<String>（文件路徑），不是 FileRes 對象
@JsonSerializable()
class CourseFilesRes {
  final String courseId;
  final String courseName;
  final List<String> files;

  CourseFilesRes(this.courseId, this.courseName, this.files);

  factory CourseFilesRes.fromJson(Map<String, dynamic> json) =>
      _$CourseFilesResFromJson(json);

  Map<String, dynamic> toJson() => _$CourseFilesResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CourseFilesRes.fromJson(json);
}
