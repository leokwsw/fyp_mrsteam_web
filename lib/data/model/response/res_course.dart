import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'res_course_file.dart';

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

/// Parse files array — supports path strings or full `CourseFile` maps.
List<CourseFile> _parseFiles(dynamic json) {
  if (json == null) return [];
  if (json is! List) return [];
  
  return json.map((item) {
    if (item is String) {
      // Old format: just file path
      final path = item;
      final filename = path.split('/').last;
      return CourseFile(
        originalName: filename,
        filename: filename,
        path: path,
        url: '',
      );
    } else if (item is Map<String, dynamic>) {
      // New format: CourseFile object
      return CourseFile.fromJson(item);
    }
    // Fallback
    return CourseFile(
      originalName: 'unknown',
      filename: 'unknown',
      path: '',
      url: '',
    );
  }).toList();
}

List<CourseTimestampRes> _parseCourseTimestamps(dynamic json) {
  if (json == null) return [];
  if (json is! List) return [];
  return json.map((item) {
    if (item is Map<String, dynamic>) {
      return CourseTimestampRes.fromJson(item);
    }
    if (item is String) {
      final s = item.trim();
      if (s.startsWith('{')) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          return CourseTimestampRes.fromJson(m);
        } catch (_) {}
      }
    }
    return CourseTimestampRes(0, 0);
  }).toList();
}

@JsonSerializable()
class CourseRes {
  @JsonKey(name: '_id')
  final String? id;
  final String name;
  final String overview;
  final String room;
  @JsonKey(fromJson: _parseFiles)
  final List<CourseFile> files;
  final String schoolId;
  final String tutorId;
  @JsonKey(fromJson: _parseCourseTimestamps)
  final List<CourseTimestampRes> timestamps;

  @JsonKey(readValue: _readCourseCode, fromJson: _toSafeString)
  final String courseCode;

  @JsonKey(readValue: _readSubjectShortName, fromJson: _toSafeString)
  final String subjectShortName;

  static String _toSafeString(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  static Object? _readCourseCode(Map json, String key) {
    return json['courseCode'] ?? json['course_code'] ?? json['code'];
  }

  static Object? _readSubjectShortName(Map json, String key) {
    return json['subjectShortName'] ??
        json['subject_short_name'] ??
        json['subjectCode'] ??
        json['subject_code'];
  }

  String get subjectCode {
    if (courseCode.isNotEmpty) {
      final match = RegExp(r'^[A-Za-z]+').firstMatch(courseCode);
      if (match != null) return match.group(0)!;
    }
    return subjectShortName;
  }

  CourseRes(
    this.name,
    this.overview,
    this.room,
    this.files,
    this.schoolId,
    this.tutorId,
    this.timestamps, {
    this.id,
    this.courseCode = '',
    this.subjectShortName = '',
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
@JsonSerializable()
class CourseFilesRes {
  final String courseId;
  final String courseName;
  @JsonKey(fromJson: _parseFiles)
  final List<CourseFile> files;

  CourseFilesRes(this.courseId, this.courseName, this.files);

  factory CourseFilesRes.fromJson(Map<String, dynamic> json) =>
      _$CourseFilesResFromJson(json);

  Map<String, dynamic> toJson() => _$CourseFilesResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CourseFilesRes.fromJson(json);
}
