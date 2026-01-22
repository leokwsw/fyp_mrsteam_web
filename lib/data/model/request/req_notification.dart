import 'package:json_annotation/json_annotation.dart';

part 'req_notification.g.dart';

@JsonSerializable()
class RegisterDeviceTokenReq {
  final String fcmToken;

  RegisterDeviceTokenReq(this.fcmToken);

  factory RegisterDeviceTokenReq.fromJson(Map<String, dynamic> json) =>
      _$RegisterDeviceTokenReqFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDeviceTokenReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      RegisterDeviceTokenReq.fromJson(json);
}

@JsonSerializable()
class CreateNotificationTemplateReq {
  final String name;
  final String type;
  final String title;
  final String content;
  final bool? isActive;

  CreateNotificationTemplateReq(
    this.name,
    this.type,
    this.title,
    this.content, {
    this.isActive,
  });

  factory CreateNotificationTemplateReq.fromJson(Map<String, dynamic> json) =>
      _$CreateNotificationTemplateReqFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNotificationTemplateReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CreateNotificationTemplateReq.fromJson(json);
}

@JsonSerializable()
class UpdateNotificationTemplateReq {
  final String? name;
  final String? type;
  final String? title;
  final String? content;
  final bool? isActive;

  UpdateNotificationTemplateReq({
    this.name,
    this.type,
    this.title,
    this.content,
    this.isActive,
  });

  factory UpdateNotificationTemplateReq.fromJson(Map<String, dynamic> json) =>
      _$UpdateNotificationTemplateReqFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNotificationTemplateReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UpdateNotificationTemplateReq.fromJson(json);
}
