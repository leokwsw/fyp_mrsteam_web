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

ForgotPasswordReq _$ForgotPasswordReqFromJson(Map<String, dynamic> json) =>
    ForgotPasswordReq(json['email'] as String);

Map<String, dynamic> _$ForgotPasswordReqToJson(ForgotPasswordReq instance) =>
    <String, dynamic>{'email': instance.email};

VerifyOtpReq _$VerifyOtpReqFromJson(Map<String, dynamic> json) =>
    VerifyOtpReq(json['email'] as String, json['otp'] as String);

Map<String, dynamic> _$VerifyOtpReqToJson(VerifyOtpReq instance) =>
    <String, dynamic>{'email': instance.email, 'otp': instance.otp};

ResetPasswordWithResetTokenReq _$ResetPasswordWithResetTokenReqFromJson(
  Map<String, dynamic> json,
) => ResetPasswordWithResetTokenReq(
  json['resetToken'] as String,
  json['newPassword'] as String,
);

Map<String, dynamic> _$ResetPasswordWithResetTokenReqToJson(
  ResetPasswordWithResetTokenReq instance,
) => <String, dynamic>{
  'resetToken': instance.resetToken,
  'newPassword': instance.newPassword,
};
