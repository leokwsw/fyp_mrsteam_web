// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshTokenReq _$RefreshTokenReqFromJson(Map<String, dynamic> json) =>
    RefreshTokenReq(
      json['refreshToken'] as String,
      json['sessionId'] as String,
    );

Map<String, dynamic> _$RefreshTokenReqToJson(RefreshTokenReq instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
      'sessionId': instance.sessionId,
    };

ChangePasswordReq _$ChangePasswordReqFromJson(Map<String, dynamic> json) =>
    ChangePasswordReq(
      json['oldPassword'] as String,
      json['newPassword'] as String,
    );

Map<String, dynamic> _$ChangePasswordReqToJson(ChangePasswordReq instance) =>
    <String, dynamic>{
      'oldPassword': instance.oldPassword,
      'newPassword': instance.newPassword,
    };
