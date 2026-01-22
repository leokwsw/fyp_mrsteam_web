// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginReq _$LoginReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LoginReq', json, ($checkedConvert) {
      final val = LoginReq(
        $checkedConvert('username', (v) => v as String),
        $checkedConvert('password', (v) => v as String),
        role: $checkedConvert('role', (v) => v as String? ?? 'tutor'),
      );
      return val;
    });

Map<String, dynamic> _$LoginReqToJson(LoginReq instance) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'role': instance.role,
};
