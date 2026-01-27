// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRes _$LoginResFromJson(Map<String, dynamic> json) => LoginRes(
  json['access_token'] as String,
  json['refresh_token'] as String,
  json['session_id'] as String,
  (json['expires_in'] as num).toInt(),
  User.fromJson(json['user'] as Map<String, dynamic>),
  json['message'] as String,
);

Map<String, dynamic> _$LoginResToJson(LoginRes instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'session_id': instance.sessionId,
  'expires_in': instance.expiresIn,
  'user': instance.user,
  'message': instance.message,
};
