
import 'package:json_annotation/json_annotation.dart';

part 'req_login.g.dart';

@JsonSerializable()
class LoginReq {
  final String username;
  final String password;
  final String role;

  LoginReq(
    this.username,
    this.password, {
      this.role = 'tutor',
    });

  factory LoginReq.fromJson(Map<String, dynamic> json) => _$LoginReqFromJson(json);
  Map<String, dynamic> toJson() => _$LoginReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => LoginReq.fromJson(json);
}