// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUserReq _$CreateUserReqFromJson(Map<String, dynamic> json) =>
    CreateUserReq(
      json['email'] as String,
      json['password'] as String,
      json['name'] as String,
      username: json['username'] as String?,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$CreateUserReqToJson(CreateUserReq instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'role': instance.role,
    };

UpdateUserReq _$UpdateUserReqFromJson(Map<String, dynamic> json) =>
    UpdateUserReq(
      email: json['email'] as String?,
      password: json['password'] as String?,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      fcmToken: json['fcmToken'] as String?,
      mustChangePassword: json['mustChangePassword'] as bool?,
    );

Map<String, dynamic> _$UpdateUserReqToJson(UpdateUserReq instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'avatar': instance.avatar,
      'fcmToken': instance.fcmToken,
      'mustChangePassword': instance.mustChangePassword,
    };

ActiveUserReq _$ActiveUserReqFromJson(Map<String, dynamic> json) =>
    ActiveUserReq(isActive: json['isActive'] as String?);

Map<String, dynamic> _$ActiveUserReqToJson(ActiveUserReq instance) =>
    <String, dynamic>{'isActive': instance.isActive};

ResetPasswordReq _$ResetPasswordReqFromJson(Map<String, dynamic> json) =>
    ResetPasswordReq(json['newPassword'] as String);

Map<String, dynamic> _$ResetPasswordReqToJson(ResetPasswordReq instance) =>
    <String, dynamic>{'newPassword': instance.newPassword};
