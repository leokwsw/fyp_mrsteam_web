// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_leave.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLeaveReq _$CreateLeaveReqFromJson(Map<String, dynamic> json) =>
    CreateLeaveReq(
      json['reason'] as String,
      json['startDate'] as String,
      json['endDate'] as String,
      courseId: json['courseId'] as String?,
    );

Map<String, dynamic> _$CreateLeaveReqToJson(CreateLeaveReq instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'reason': instance.reason,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

UpdateLeaveReq _$UpdateLeaveReqFromJson(Map<String, dynamic> json) =>
    UpdateLeaveReq(
      courseId: json['courseId'] as String?,
      reason: json['reason'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );

Map<String, dynamic> _$UpdateLeaveReqToJson(UpdateLeaveReq instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'reason': instance.reason,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

ApproveLeaveReq _$ApproveLeaveReqFromJson(Map<String, dynamic> json) =>
    ApproveLeaveReq(
      json['action'] as String,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$ApproveLeaveReqToJson(ApproveLeaveReq instance) =>
    <String, dynamic>{
      'action': instance.action,
      'rejectionReason': instance.rejectionReason,
    };
