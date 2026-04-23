import 'package:json_annotation/json_annotation.dart';

part 'req_auth.g.dart';

@JsonSerializable()
class RefreshTokenReq {
  final String refreshToken;
  final String sessionId;

  RefreshTokenReq(this.refreshToken, this.sessionId);

  factory RefreshTokenReq.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenReqFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      RefreshTokenReq.fromJson(json);
}

@JsonSerializable()
class ChangePasswordReq {
  final String oldPassword;
  final String newPassword;

  ChangePasswordReq(this.oldPassword, this.newPassword);

  factory ChangePasswordReq.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordReqFromJson(json);

  Map<String, dynamic> toJson() => _$ChangePasswordReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      ChangePasswordReq.fromJson(json);
}

@JsonSerializable()
class ForgotPasswordReq {
  final String email;

  ForgotPasswordReq(this.email);

  factory ForgotPasswordReq.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordReqFromJson(json);

  Map<String, dynamic> toJson() => _$ForgotPasswordReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      ForgotPasswordReq.fromJson(json);
}

@JsonSerializable()
class VerifyOtpReq {
  final String email;
  final String otp;

  VerifyOtpReq(this.email, this.otp);

  factory VerifyOtpReq.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpReqFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      VerifyOtpReq.fromJson(json);
}

@JsonSerializable()
class ResetPasswordWithResetTokenReq {
  final String resetToken;
  final String newPassword;

  ResetPasswordWithResetTokenReq(this.resetToken, this.newPassword);

  factory ResetPasswordWithResetTokenReq.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordWithResetTokenReqFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ResetPasswordWithResetTokenReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      ResetPasswordWithResetTokenReq.fromJson(json);
}
