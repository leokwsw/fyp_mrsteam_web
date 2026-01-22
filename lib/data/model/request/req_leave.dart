import 'package:json_annotation/json_annotation.dart';

part 'req_leave.g.dart';

@JsonSerializable()
class CreateLeaveReq {
  final String? courseId;
  final String reason;
  final String startDate;
  final String endDate;

  CreateLeaveReq(this.reason, this.startDate, this.endDate, {this.courseId});

  factory CreateLeaveReq.fromJson(Map<String, dynamic> json) =>
      _$CreateLeaveReqFromJson(json);

  Map<String, dynamic> toJson() => _$CreateLeaveReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CreateLeaveReq.fromJson(json);
}

@JsonSerializable()
class UpdateLeaveReq {
  final String? courseId;
  final String? reason;
  final String? startDate;
  final String? endDate;

  UpdateLeaveReq({this.courseId, this.reason, this.startDate, this.endDate});

  factory UpdateLeaveReq.fromJson(Map<String, dynamic> json) =>
      _$UpdateLeaveReqFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateLeaveReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UpdateLeaveReq.fromJson(json);
}

@JsonSerializable()
class ApproveLeaveReq {
  final String action;
  final String? rejectionReason;

  ApproveLeaveReq(this.action, {this.rejectionReason});

  factory ApproveLeaveReq.fromJson(Map<String, dynamic> json) =>
      _$ApproveLeaveReqFromJson(json);

  Map<String, dynamic> toJson() => _$ApproveLeaveReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      ApproveLeaveReq.fromJson(json);
}
