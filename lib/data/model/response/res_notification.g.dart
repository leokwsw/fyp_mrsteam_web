// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationRes _$NotificationResFromJson(Map<String, dynamic> json) =>
    NotificationRes(
      json['userId'] as String,
      json['type'] as String,
      json['title'] as String,
      json['content'] as String,
      json['isRead'] as bool,
      json['sentAt'] as String,
      id: json['_id'] as String?,
      courseId: json['courseId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

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
    NotificationListRes(
      (json['items'] as List<dynamic>)
          .map((e) => NotificationRes.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['total'] as num).toInt(),
      (json['page'] as num).toInt(),
      (json['limit'] as num).toInt(),
      (json['pages'] as num).toInt(),
    );

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
    UnreadCountRes((json['count'] as num).toInt());

Map<String, dynamic> _$UnreadCountResToJson(UnreadCountRes instance) =>
    <String, dynamic>{'count': instance.count};
