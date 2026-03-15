// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_course_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseFile _$CourseFileFromJson(Map<String, dynamic> json) => CourseFile(
  originalName: json['originalName'] as String,
  filename: json['filename'] as String,
  path: json['path'] as String,
  url: json['url'] as String,
);

Map<String, dynamic> _$CourseFileToJson(CourseFile instance) =>
    <String, dynamic>{
      'originalName': instance.originalName,
      'filename': instance.filename,
      'path': instance.path,
      'url': instance.url,
    };
