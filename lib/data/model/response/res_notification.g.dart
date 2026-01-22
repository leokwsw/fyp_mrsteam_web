// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationRes _$NotificationResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NotificationRes', json, ($checkedConvert) {
      final val = NotificationRes(
        $checkedConvert('userId', (v) => v as String),
        $checkedConvert('type', (v) => v as String),
        $checkedConvert('title', (v) => v as String),
        $checkedConvert('content', (v) => v as String),
        $checkedConvert('isRead', (v) => v as bool),
        $checkedConvert('sentAt', (v) => v as String),
        id: $checkedConvert('_id', (v) => v as String?),
        courseId: $checkedConvert('courseId', (v) => v as String?),
        createdAt: $checkedConvert('createdAt', (v) => v as String?),
        updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'id': '_id'});

Map<String, dynamic> _$NotificationResToJson(NotificationRes instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'title': instance.title,
      'content': instance.content,
      'courseId': instance.courseId,
      'isRead': instance.isRead,
      'sentAt': instance.sentAt,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

NotificationListRes _$NotificationListResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NotificationListRes', json, ($checkedConvert) {
      final val = NotificationListRes(
        $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => NotificationRes.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        $checkedConvert('total', (v) => (v as num).toInt()),
        $checkedConvert('page', (v) => (v as num).toInt()),
        $checkedConvert('limit', (v) => (v as num).toInt()),
        $checkedConvert('pages', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$NotificationListResToJson(
  NotificationListRes instance,
) => <String, dynamic>{
  'items': instance.items,
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
  'pages': instance.pages,
};

UnreadCountRes _$UnreadCountResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UnreadCountRes', json, ($checkedConvert) {
      final val = UnreadCountRes(
        $checkedConvert('count', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$UnreadCountResToJson(UnreadCountRes instance) =>
    <String, dynamic>{'count': instance.count};
