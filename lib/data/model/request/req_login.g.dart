// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginReq _$LoginReqFromJson(Map<String, dynamic> json) => LoginReq(
  json['username'] as String,
  json['password'] as String,
  role: json['role'] as String? ?? 'tutor',
);

Map<String, dynamic> _$LoginReqToJson(LoginReq instance) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'role': instance.role,
};
