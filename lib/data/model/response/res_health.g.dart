// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthRes _$HealthResFromJson(Map<String, dynamic> json) => HealthRes(
  json['status'] as String,
  info: json['info'] as Map<String, dynamic>?,
  error: json['error'] as Map<String, dynamic>?,
  details: json['details'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$HealthResToJson(HealthRes instance) => <String, dynamic>{
  'status': instance.status,
  'info': instance.info,
  'error': instance.error,
  'details': instance.details,
};

ServerTimeRes _$ServerTimeResFromJson(Map<String, dynamic> json) =>
    ServerTimeRes(
      json['iso'] as String,
      json['unixMs'] as num,
      json['timezone'] as String,
      json['timezoneOffsetMinutes'] as num,
    );

Map<String, dynamic> _$ServerTimeResToJson(ServerTimeRes instance) =>
    <String, dynamic>{
      'iso': instance.iso,
      'unixMs': instance.unixMs,
      'timezone': instance.timezone,
      'timezoneOffsetMinutes': instance.timezoneOffsetMinutes,
    };
