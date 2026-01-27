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
