// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_common_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommonMessage _$CommonMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommonMessage', json, ($checkedConvert) {
      final val = CommonMessage($checkedConvert('message', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$CommonMessageToJson(CommonMessage instance) =>
    <String, dynamic>{'message': instance.message};
