// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseTimestampRes _$CourseTimestampResFromJson(Map<String, dynamic> json) =>
    CourseTimestampRes(json['start'] as num, json['end'] as num);

Map<String, dynamic> _$CourseTimestampResToJson(CourseTimestampRes instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};

CourseRes _$CourseResFromJson(Map<String, dynamic> json) => CourseRes(
  json['name'] as String,
  json['overview'] as String,
  json['room'] as String,
  (json['files'] as List<dynamic>).map((e) => e as String).toList(),
  json['schoolId'] as String,
  json['tutorId'] as String,
  (json['timestamps'] as List<dynamic>)
      .map((e) => CourseTimestampRes.fromJson(e as Map<String, dynamic>))
      .toList(),
  id: json['_id'] as String?,
  isDeleted: json['isDeleted'] as bool?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$CourseResToJson(CourseRes instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'overview': instance.overview,
  'room': instance.room,
  'files': instance.files,
  'schoolId': instance.schoolId,
  'tutorId': instance.tutorId,
  'timestamps': instance.timestamps,
  'isDeleted': instance.isDeleted,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

CourseListRes _$CourseListResFromJson(Map<String, dynamic> json) =>
    CourseListRes(
      (json['items'] as List<dynamic>)
          .map((e) => CourseRes.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['total'] as num).toInt(),
      (json['page'] as num).toInt(),
      (json['limit'] as num).toInt(),
      (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$CourseListResToJson(CourseListRes instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'pages': instance.pages,
    };

CourseFilesRes _$CourseFilesResFromJson(Map<String, dynamic> json) =>
    CourseFilesRes(
      json['courseId'] as String,
      json['courseName'] as String,
      (json['files'] as List<dynamic>)
          .map((e) => FileRes.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseFilesResToJson(CourseFilesRes instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'courseName': instance.courseName,
      'files': instance.files,
    };
