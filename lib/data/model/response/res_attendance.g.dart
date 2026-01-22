// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceRes _$AttendanceResFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AttendanceRes',
      json,
      ($checkedConvert) {
        final val = AttendanceRes(
          $checkedConvert('courseId', (v) => v as String),
          $checkedConvert(
            'timestamp',
            (v) => CourseTimestampRes.fromJson(v as Map<String, dynamic>),
          ),
          $checkedConvert('timestamp_index', (v) => v as num),
          $checkedConvert('checked', (v) => v as bool),
          $checkedConvert('tutorId', (v) => v as String),
          $checkedConvert('schoolId', (v) => v as String),
          id: $checkedConvert('_id', (v) => v as String?),
          photoUrl: $checkedConvert('photoUrl', (v) => v as String?),
          checkInTime: $checkedConvert('checkInTime', (v) => v as String?),
          isDeleted: $checkedConvert('isDeleted', (v) => v as bool?),
          createdAt: $checkedConvert('createdAt', (v) => v as String?),
          updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'timestampIndex': 'timestamp_index', 'id': '_id'},
    );

Map<String, dynamic> _$AttendanceResToJson(AttendanceRes instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'courseId': instance.courseId,
      'timestamp': instance.timestamp,
      'timestamp_index': instance.timestampIndex,
      'checked': instance.checked,
      'tutorId': instance.tutorId,
      'schoolId': instance.schoolId,
      'photoUrl': instance.photoUrl,
      'checkInTime': instance.checkInTime,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

AttendanceListRes _$AttendanceListResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendanceListRes', json, ($checkedConvert) {
      final val = AttendanceListRes(
        $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AttendanceRes.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        $checkedConvert('total', (v) => (v as num).toInt()),
        $checkedConvert('page', (v) => (v as num).toInt()),
        $checkedConvert('limit', (v) => (v as num).toInt()),
        $checkedConvert('pages', (v) => (v as num).toInt()),
        courses: $checkedConvert(
          'courses',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, CourseRes.fromJson(e as Map<String, dynamic>)),
          ),
        ),
        schools: $checkedConvert(
          'schools',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, SchoolRes.fromJson(e as Map<String, dynamic>)),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AttendanceListResToJson(AttendanceListRes instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'pages': instance.pages,
      'courses': instance.courses,
      'schools': instance.schools,
    };
