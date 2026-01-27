// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseTimestampReq _$CourseTimestampReqFromJson(Map<String, dynamic> json) =>
    CourseTimestampReq(json['start'] as num, json['end'] as num);

Map<String, dynamic> _$CourseTimestampReqToJson(CourseTimestampReq instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};

CreateCourseReq _$CreateCourseReqFromJson(Map<String, dynamic> json) =>
    CreateCourseReq(
      json['name'] as String,
      json['overview'] as String,
      json['room'] as String,
      (json['files'] as List<dynamic>).map((e) => e as String).toList(),
      json['schoolId'] as String,
      json['tutorId'] as String,
      (json['timestamps'] as List<dynamic>)
          .map((e) => CourseTimestampReq.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateCourseReqToJson(CreateCourseReq instance) =>
    <String, dynamic>{
      'name': instance.name,
      'overview': instance.overview,
      'room': instance.room,
      'files': instance.files,
      'schoolId': instance.schoolId,
      'tutorId': instance.tutorId,
      'timestamps': instance.timestamps,
    };

UpdateCourseReq _$UpdateCourseReqFromJson(Map<String, dynamic> json) =>
    UpdateCourseReq(
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      room: json['room'] as String?,
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      schoolId: json['schoolId'] as String?,
      tutorId: json['tutorId'] as String?,
      timestamps: (json['timestamps'] as List<dynamic>?)
          ?.map((e) => CourseTimestampReq.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdateCourseReqToJson(UpdateCourseReq instance) =>
    <String, dynamic>{
      'name': instance.name,
      'overview': instance.overview,
      'room': instance.room,
      'files': instance.files,
      'schoolId': instance.schoolId,
      'tutorId': instance.tutorId,
      'timestamps': instance.timestamps,
    };
