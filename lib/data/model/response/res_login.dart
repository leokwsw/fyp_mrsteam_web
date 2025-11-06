import 'package:fyp_mrsteam_web/data/model/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'res_login.g.dart';

@JsonSerializable()
class LoginRes {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  User user;
  final String message;

  LoginRes(
    this.accessToken,
    this.refreshToken,
    this.sessionId,
    this.expiresIn,
    this.user,
    this.message,
  );

  factory LoginRes.fromJson(Map<String, dynamic> json) => _$LoginResFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => LoginRes.fromJson(json);
}