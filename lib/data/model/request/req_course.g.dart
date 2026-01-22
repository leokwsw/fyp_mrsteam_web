// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseTimestampReq _$CourseTimestampReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CourseTimestampReq', json, ($checkedConvert) {
      final val = CourseTimestampReq(
        $checkedConvert('start', (v) => v as num),
        $checkedConvert('end', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$CourseTimestampReqToJson(CourseTimestampReq instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};

CreateCourseReq _$CreateCourseReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateCourseReq', json, ($checkedConvert) {
      final val = CreateCourseReq(
        $checkedConvert('name', (v) => v as String),
        $checkedConvert('overview', (v) => v as String),
        $checkedConvert('room', (v) => v as String),
        $checkedConvert(
          'files',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        $checkedConvert('schoolId', (v) => v as String),
        $checkedConvert('tutorId', (v) => v as String),
        $checkedConvert(
          'timestamps',
          (v) => (v as List<dynamic>)
              .map(
                (e) => CourseTimestampReq.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

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
    $checkedCreate('UpdateCourseReq', json, ($checkedConvert) {
      final val = UpdateCourseReq(
        name: $checkedConvert('name', (v) => v as String?),
        overview: $checkedConvert('overview', (v) => v as String?),
        room: $checkedConvert('room', (v) => v as String?),
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        schoolId: $checkedConvert('schoolId', (v) => v as String?),
        tutorId: $checkedConvert('tutorId', (v) => v as String?),
        timestamps: $checkedConvert(
          'timestamps',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => CourseTimestampReq.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

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
