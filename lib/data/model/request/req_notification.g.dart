// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDeviceTokenReq _$RegisterDeviceTokenReqFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RegisterDeviceTokenReq', json, ($checkedConvert) {
  final val = RegisterDeviceTokenReq(
    $checkedConvert('fcmToken', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RegisterDeviceTokenReqToJson(
  RegisterDeviceTokenReq instance,
) => <String, dynamic>{'fcmToken': instance.fcmToken};

CreateNotificationTemplateReq _$CreateNotificationTemplateReqFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateNotificationTemplateReq', json, ($checkedConvert) {
  final val = CreateNotificationTemplateReq(
    $checkedConvert('name', (v) => v as String),
    $checkedConvert('type', (v) => v as String),
    $checkedConvert('title', (v) => v as String),
    $checkedConvert('content', (v) => v as String),
    isActive: $checkedConvert('isActive', (v) => v as bool?),
  );
  return val;
});

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
) => $checkedCreate('UpdateNotificationTemplateReq', json, ($checkedConvert) {
  final val = UpdateNotificationTemplateReq(
    name: $checkedConvert('name', (v) => v as String?),
    type: $checkedConvert('type', (v) => v as String?),
    title: $checkedConvert('title', (v) => v as String?),
    content: $checkedConvert('content', (v) => v as String?),
    isActive: $checkedConvert('isActive', (v) => v as bool?),
  );
  return val;
});

Map<String, dynamic> _$UpdateNotificationTemplateReqToJson(
  UpdateNotificationTemplateReq instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'title': instance.title,
  'content': instance.content,
  'isActive': instance.isActive,
};
