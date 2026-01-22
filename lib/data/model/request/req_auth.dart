import 'package:json_annotation/json_annotation.dart';

part 'req_auth.g.dart';

@JsonSerializable()
class RefreshTokenReq {
  final String refreshToken;
  final String sessionId;

  RefreshTokenReq(this.refreshToken, this.sessionId);

  factory RefreshTokenReq.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenReqFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      RefreshTokenReq.fromJson(json);
}

@JsonSerializable()
class ChangePasswordReq {
  final String oldPassword;
  final String newPassword;

  ChangePasswordReq(this.oldPassword, this.newPassword);

  factory ChangePasswordReq.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordReqFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      ChangePasswordReq.fromJson(json);
}
