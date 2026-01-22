// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseTimestampRes _$CourseTimestampResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CourseTimestampRes', json, ($checkedConvert) {
      final val = CourseTimestampRes(
        $checkedConvert('start', (v) => v as num),
        $checkedConvert('end', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$CourseTimestampResToJson(CourseTimestampRes instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};

CourseRes _$CourseResFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CourseRes',
  json,
  ($checkedConvert) {
    final val = CourseRes(
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
            .map((e) => CourseTimestampRes.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      id: $checkedConvert('_id', (v) => v as String?),
      isDeleted: $checkedConvert('isDeleted', (v) => v as bool?),
      createdAt: $checkedConvert('createdAt', (v) => v as String?),
      updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'id': '_id'},
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
    $checkedCreate('CourseListRes', json, ($checkedConvert) {
      final val = CourseListRes(
        $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => CourseRes.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        $checkedConvert('total', (v) => (v as num).toInt()),
        $checkedConvert('page', (v) => (v as num).toInt()),
        $checkedConvert('limit', (v) => (v as num).toInt()),
        $checkedConvert('pages', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CourseListResToJson(CourseListRes instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'pages': instance.pages,
    };

CourseFilesRes _$CourseFilesResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CourseFilesRes', json, ($checkedConvert) {
      final val = CourseFilesRes(
        $checkedConvert('courseId', (v) => v as String),
        $checkedConvert('courseName', (v) => v as String),
        $checkedConvert(
          'files',
          (v) => (v as List<dynamic>)
              .map((e) => FileRes.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CourseFilesResToJson(CourseFilesRes instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'courseName': instance.courseName,
      'files': instance.files,
    };
