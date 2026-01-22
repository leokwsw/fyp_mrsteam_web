// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRes _$LoginResFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LoginRes',
  json,
  ($checkedConvert) {
    final val = LoginRes(
      $checkedConvert('access_token', (v) => v as String),
      $checkedConvert('refresh_token', (v) => v as String),
      $checkedConvert('session_id', (v) => v as String),
      $checkedConvert('expires_in', (v) => (v as num).toInt()),
      $checkedConvert('user', (v) => User.fromJson(v as Map<String, dynamic>)),
      $checkedConvert('message', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'accessToken': 'access_token',
    'refreshToken': 'refresh_token',
    'sessionId': 'session_id',
    'expiresIn': 'expires_in',
  },
);

Map<String, dynamic> _$LoginResToJson(LoginRes instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'session_id': instance.sessionId,
  'expires_in': instance.expiresIn,
  'user': instance.user,
  'message': instance.message,
};
