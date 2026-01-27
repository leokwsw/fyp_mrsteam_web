// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_logout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogoutReq _$LogoutReqFromJson(Map<String, dynamic> json) => LogoutReq(
  json['sessionId'] as String,
  logoutAll: json['logoutAll'] as bool? ?? false,
);

Map<String, dynamic> _$LogoutReqToJson(LogoutReq instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'logoutAll': instance.logoutAll,
};
