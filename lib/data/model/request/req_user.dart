import 'package:json_annotation/json_annotation.dart';

part 'req_user.g.dart';

@JsonSerializable()
class CreateUserReq {
  final String? username;
  final String email;
  final String password;
  final String name;
  final String? role;

  CreateUserReq(
    this.email,
    this.password,
    this.name, {
    this.username,
    this.role,
  });

  factory CreateUserReq.fromJson(Map<String, dynamic> json) =>
      _$CreateUserReqFromJson(json);

  Map<String, dynamic> toJson() => _$CreateUserReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CreateUserReq.fromJson(json);
}

@JsonSerializable()
class UpdateUserReq {
  final String? email;
  final String? password;
  final String? name;
  final String? avatar;
  final String? fcmToken;
  final bool? mustChangePassword;

  UpdateUserReq({
    this.email,
    this.password,
    this.name,
    this.avatar,
    this.fcmToken,
    this.mustChangePassword,
  });

  factory UpdateUserReq.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserReqFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UpdateUserReq.fromJson(json);
}

@JsonSerializable()
class ActiveUserReq {
  final String? isActive;

  ActiveUserReq({this.isActive});

  factory ActiveUserReq.fromJson(Map<String, dynamic> json) =>
      _$ActiveUserReqFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveUserReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      ActiveUserReq.fromJson(json);
}

@JsonSerializable()
class ResetPasswordReq {
  final String newPassword;

  ResetPasswordReq(this.newPassword);

  factory ResetPasswordReq.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordReqFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      ResetPasswordReq.fromJson(json);
}
