// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageRes _$MessageResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MessageRes', json, ($checkedConvert) {
      final val = MessageRes(
        $checkedConvert('success', (v) => v as bool),
        $checkedConvert('message', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MessageResToJson(MessageRes instance) =>
    <String, dynamic>{'success': instance.success, 'message': instance.message};
