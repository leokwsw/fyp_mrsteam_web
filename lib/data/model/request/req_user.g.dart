// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUserReq _$CreateUserReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateUserReq', json, ($checkedConvert) {
      final val = CreateUserReq(
        $checkedConvert('email', (v) => v as String),
        $checkedConvert('password', (v) => v as String),
        $checkedConvert('name', (v) => v as String),
        username: $checkedConvert('username', (v) => v as String?),
        role: $checkedConvert('role', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CreateUserReqToJson(CreateUserReq instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'role': instance.role,
    };

UpdateUserReq _$UpdateUserReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateUserReq', json, ($checkedConvert) {
      final val = UpdateUserReq(
        email: $checkedConvert('email', (v) => v as String?),
        password: $checkedConvert('password', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String?),
        avatar: $checkedConvert('avatar', (v) => v as String?),
        fcmToken: $checkedConvert('fcmToken', (v) => v as String?),
        mustChangePassword: $checkedConvert(
          'mustChangePassword',
          (v) => v as bool?,
        ),
      );
      return val;
    });

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
    $checkedCreate('ActiveUserReq', json, ($checkedConvert) {
      final val = ActiveUserReq(
        isActive: $checkedConvert('isActive', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ActiveUserReqToJson(ActiveUserReq instance) =>
    <String, dynamic>{'isActive': instance.isActive};

ResetPasswordReq _$ResetPasswordReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResetPasswordReq', json, ($checkedConvert) {
      final val = ResetPasswordReq(
        $checkedConvert('newPassword', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ResetPasswordReqToJson(ResetPasswordReq instance) =>
    <String, dynamic>{'newPassword': instance.newPassword};
