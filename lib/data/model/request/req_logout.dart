import 'package:json_annotation/json_annotation.dart';

part 'req_logout.g.dart';

@JsonSerializable()
class LogoutReq {
  final String sessionId;
  final bool logoutAll;

  LogoutReq(
      this.sessionId,{
        this.logoutAll = false,
      });

  factory LogoutReq.fromJson(Map<String, dynamic> json) => _$LogoutReqFromJson(json);
  Map<String, dynamic> toJson() => _$LogoutReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => LogoutReq.fromJson(json);
}