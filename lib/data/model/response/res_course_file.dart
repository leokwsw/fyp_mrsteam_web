import 'package:json_annotation/json_annotation.dart';

part 'res_course_file.g.dart';

/// Course File DTO - represents a file attached to a course
@JsonSerializable()
class CourseFile {
  final String originalName;
  final String filename;
  final String path;
  final String url;

  CourseFile({
    required this.originalName,
    required this.filename,
    required this.path,
    required this.url,
  });

  factory CourseFile.fromJson(Map<String, dynamic> json) =>
      _$CourseFileFromJson(json);

  Map<String, dynamic> toJson() => _$CourseFileToJson(this);
}
