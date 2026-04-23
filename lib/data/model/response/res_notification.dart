import 'package:json_annotation/json_annotation.dart';

part 'res_notification.g.dart';

@JsonSerializable()
class NotificationRes {
  @JsonKey(name: '_id')
  final String? id;
  final String userId;
  final String type;
  final String title;
  final String content;
  final String? courseId;
  final bool isRead;
  final String sentAt;
  final String? createdAt;
  final String? updatedAt;

  NotificationRes(
    this.userId,
    this.type,
    this.title,
    this.content,
    this.isRead,
    this.sentAt, {
    this.id,
    this.courseId,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationRes.fromJson(Map<String, dynamic> json) =>
      _$NotificationResFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      NotificationRes.fromJson(json);
}

@JsonSerializable()
class NotificationListRes {
  final List<NotificationRes> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  NotificationListRes(this.items, this.total, this.page, this.limit, this.pages);

  factory NotificationListRes.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationListResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      NotificationListRes.fromJson(json);
}

@JsonSerializable()
class UnreadCountRes {
  final int count;

  UnreadCountRes(this.count);

  factory UnreadCountRes.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResFromJson(json);

  Map<String, dynamic> toJson() => _$UnreadCountResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UnreadCountRes.fromJson(json);
}

@JsonSerializable()
class BroadcastNotificationRes {
  final bool success;
  final String message;
  final int totalUsers;
  final int notificationsCreated;
  final int targetDevices;
  final int successCount;
  final int failureCount;

  BroadcastNotificationRes(
    this.success,
    this.message,
    this.totalUsers,
    this.notificationsCreated,
    this.targetDevices,
    this.successCount,
    this.failureCount,
  );

  factory BroadcastNotificationRes.fromJson(Map<String, dynamic> json) =>
      _$BroadcastNotificationResFromJson(json);

  Map<String, dynamic> toJson() => _$BroadcastNotificationResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      BroadcastNotificationRes.fromJson(json);
}
