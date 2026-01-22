// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_logout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogoutReq _$LogoutReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LogoutReq', json, ($checkedConvert) {
      final val = LogoutReq(
        $checkedConvert('sessionId', (v) => v as String),
        logoutAll: $checkedConvert('logoutAll', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LogoutReqToJson(LogoutReq instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'logoutAll': instance.logoutAll,
};
