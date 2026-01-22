// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthRes _$HealthResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HealthRes', json, ($checkedConvert) {
      final val = HealthRes(
        $checkedConvert('status', (v) => v as String),
        info: $checkedConvert('info', (v) => v as Map<String, dynamic>?),
        error: $checkedConvert('error', (v) => v as Map<String, dynamic>?),
        details: $checkedConvert('details', (v) => v as Map<String, dynamic>?),
      );
      return val;
    });

Map<String, dynamic> _$HealthResToJson(HealthRes instance) => <String, dynamic>{
  'status': instance.status,
  'info': instance.info,
  'error': instance.error,
  'details': instance.details,
};
