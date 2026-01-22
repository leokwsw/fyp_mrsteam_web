// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_success.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuccessRes _$SuccessResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuccessRes', json, ($checkedConvert) {
      final val = SuccessRes($checkedConvert('success', (v) => v as bool));
      return val;
    });

Map<String, dynamic> _$SuccessResToJson(SuccessRes instance) =>
    <String, dynamic>{'success': instance.success};
