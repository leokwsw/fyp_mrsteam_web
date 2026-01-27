// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDeviceTokenReq _$RegisterDeviceTokenReqFromJson(
  Map<String, dynamic> json,
) => RegisterDeviceTokenReq(json['fcmToken'] as String);

Map<String, dynamic> _$RegisterDeviceTokenReqToJson(
  RegisterDeviceTokenReq instance,
) => <String, dynamic>{'fcmToken': instance.fcmToken};

CreateNotificationTemplateReq _$CreateNotificationTemplateReqFromJson(
  Map<String, dynamic> json,
) => CreateNotificationTemplateReq(
  json['name'] as String,
  json['type'] as String,
  json['title'] as String,
  json['content'] as String,
  isActive: json['isActive'] as bool?,
);

Map<String, dynamic> _$CreateNotificationTemplateReqToJson(
  CreateNotificationTemplateReq instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'title': instance.title,
  'content': instance.content,
  'isActive': instance.isActive,
};

UpdateNotificationTemplateReq _$UpdateNotificationTemplateReqFromJson(
  Map<String, dynamic> json,
) => UpdateNotificationTemplateReq(
  name: json['name'] as String?,
  type: json['type'] as String?,
  title: json['title'] as String?,
  content: json['content'] as String?,
  isActive: json['isActive'] as bool?,
);

Map<String, dynamic> _$UpdateNotificationTemplateReqToJson(
  UpdateNotificationTemplateReq instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'title': instance.title,
  'content': instance.content,
  'isActive': instance.isActive,
};
