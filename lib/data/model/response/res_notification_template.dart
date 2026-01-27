import 'package:json_annotation/json_annotation.dart';

part 'res_notification_template.g.dart';

@JsonSerializable()
class NotificationTemplateRes {
  @JsonKey(name: '_id')
  final String? id;
  final String name;
  final String type;
  final String title;
  final String content;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  NotificationTemplateRes(
    this.name,
    this.type,
    this.title,
    this.content,
    this.isActive, {
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationTemplateRes.fromJson(Map<String, dynamic> json) =>
      _$NotificationTemplateResFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTemplateResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      NotificationTemplateRes.fromJson(json);
}

@JsonSerializable()
class NotificationTemplateListRes {
  final List<NotificationTemplateRes> items;

  NotificationTemplateListRes(this.items);

  factory NotificationTemplateListRes.fromJson(Map<String, dynamic> json) =>
      _$NotificationTemplateListResFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTemplateListResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      NotificationTemplateListRes.fromJson(json);
}
