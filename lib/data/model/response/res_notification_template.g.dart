// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_notification_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationTemplateRes _$NotificationTemplateResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NotificationTemplateRes', json, ($checkedConvert) {
  final val = NotificationTemplateRes(
    $checkedConvert('name', (v) => v as String),
    $checkedConvert('type', (v) => v as String),
    $checkedConvert('title', (v) => v as String),
    $checkedConvert('content', (v) => v as String),
    $checkedConvert('isActive', (v) => v as bool),
    id: $checkedConvert('_id', (v) => v as String?),
    createdAt: $checkedConvert('createdAt', (v) => v as String?),
    updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'id': '_id'});

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
) => $checkedCreate('NotificationTemplateListRes', json, ($checkedConvert) {
  final val = NotificationTemplateListRes(
    $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map(
            (e) => NotificationTemplateRes.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$NotificationTemplateListResToJson(
  NotificationTemplateListRes instance,
) => <String, dynamic>{'items': instance.items};
