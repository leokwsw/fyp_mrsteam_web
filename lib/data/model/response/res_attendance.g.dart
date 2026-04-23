// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceRes _$AttendanceResFromJson(Map<String, dynamic> json) =>
    AttendanceRes(
      json['courseId'] as String,
      CourseTimestampRes.fromJson(json['timestamp'] as Map<String, dynamic>),
      json['timestamp_index'] as num,
      AttendanceRes._readStatus(json, 'status') as String,
      json['tutorId'] as String,
      json['schoolId'] as String,
      arrivedTime:
          AttendanceRes._readArrivedTime(json, 'arrivedTime') as String?,
      id: json['_id'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isDeleted: json['isDeleted'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$AttendanceResToJson(AttendanceRes instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'courseId': instance.courseId,
      'timestamp': instance.timestamp,
      'timestamp_index': instance.timestampIndex,
      'status': instance.status,
      'tutorId': instance.tutorId,
      'schoolId': instance.schoolId,
      'photoUrl': instance.photoUrl,
      'arrivedTime': instance.arrivedTime,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

AttendanceListRes _$AttendanceListResFromJson(Map<String, dynamic> json) =>
    AttendanceListRes(
      (json['items'] as List<dynamic>)
          .map((e) => AttendanceRes.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['total'] as num).toInt(),
      (json['page'] as num).toInt(),
      (json['limit'] as num).toInt(),
      (json['pages'] as num).toInt(),
      courses: (json['courses'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, CourseRes.fromJson(e as Map<String, dynamic>)),
      ),
      schools: (json['schools'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, SchoolRes.fromJson(e as Map<String, dynamic>)),
      ),
    );

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
