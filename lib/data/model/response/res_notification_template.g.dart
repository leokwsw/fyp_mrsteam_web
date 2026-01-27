// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_notification_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationTemplateRes _$NotificationTemplateResFromJson(
  Map<String, dynamic> json,
) => NotificationTemplateRes(
  json['name'] as String,
  json['type'] as String,
  json['title'] as String,
  json['content'] as String,
  json['isActive'] as bool,
  id: json['_id'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$NotificationTemplateResToJson(
  NotificationTemplateRes instance,
) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'title': instance.title,
  'content': instance.content,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

NotificationTemplateListRes _$NotificationTemplateListResFromJson(
  Map<String, dynamic> json,
) => NotificationTemplateListRes(
  (json['items'] as List<dynamic>)
      .map((e) => NotificationTemplateRes.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NotificationTemplateListResToJson(
  NotificationTemplateListRes instance,
) => <String, dynamic>{'items': instance.items};
