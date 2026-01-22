// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshTokenReq _$RefreshTokenReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RefreshTokenReq', json, ($checkedConvert) {
      final val = RefreshTokenReq(
        $checkedConvert('refreshToken', (v) => v as String),
        $checkedConvert('sessionId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RefreshTokenReqToJson(RefreshTokenReq instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
      'sessionId': instance.sessionId,
    };

ChangePasswordReq _$ChangePasswordReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChangePasswordReq', json, ($checkedConvert) {
      final val = ChangePasswordReq(
        $checkedConvert('oldPassword', (v) => v as String),
        $checkedConvert('newPassword', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ChangePasswordReqToJson(ChangePasswordReq instance) =>
    <String, dynamic>{
      'oldPassword': instance.oldPassword,
      'newPassword': instance.newPassword,
    };
