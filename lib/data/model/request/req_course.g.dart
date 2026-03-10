// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurrenceRuleReq _$RecurrenceRuleReqFromJson(Map<String, dynamic> json) =>
    RecurrenceRuleReq(
      frequency: $enumDecode(_$RecurrenceFrequencyEnumMap, json['frequency']),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      occurrenceCount: (json['occurrenceCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecurrenceRuleReqToJson(RecurrenceRuleReq instance) =>
    <String, dynamic>{
      'frequency': _$RecurrenceFrequencyEnumMap[instance.frequency]!,
      'interval': instance.interval,
      'endDate': instance.endDate?.toIso8601String(),
      'occurrenceCount': instance.occurrenceCount,
    };

const _$RecurrenceFrequencyEnumMap = {
  RecurrenceFrequency.weekly: 'weekly',
  RecurrenceFrequency.biweekly: 'biweekly',
  RecurrenceFrequency.monthly: 'monthly',
};

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
      json['subjectShortName'] as String,
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
      'subjectShortName': instance.subjectShortName,
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
      subjectShortName: json['subjectShortName'] as String?,
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
      'subjectShortName': instance.subjectShortName,
    };
