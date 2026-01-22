// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_leave.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLeaveReq _$CreateLeaveReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateLeaveReq', json, ($checkedConvert) {
      final val = CreateLeaveReq(
        $checkedConvert('reason', (v) => v as String),
        $checkedConvert('startDate', (v) => v as String),
        $checkedConvert('endDate', (v) => v as String),
        courseId: $checkedConvert('courseId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CreateLeaveReqToJson(CreateLeaveReq instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'reason': instance.reason,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

UpdateLeaveReq _$UpdateLeaveReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateLeaveReq', json, ($checkedConvert) {
      final val = UpdateLeaveReq(
        courseId: $checkedConvert('courseId', (v) => v as String?),
        reason: $checkedConvert('reason', (v) => v as String?),
        startDate: $checkedConvert('startDate', (v) => v as String?),
        endDate: $checkedConvert('endDate', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateLeaveReqToJson(UpdateLeaveReq instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'reason': instance.reason,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

ApproveLeaveReq _$ApproveLeaveReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ApproveLeaveReq', json, ($checkedConvert) {
      final val = ApproveLeaveReq(
        $checkedConvert('action', (v) => v as String),
        rejectionReason: $checkedConvert(
          'rejectionReason',
          (v) => v as String?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$ApproveLeaveReqToJson(ApproveLeaveReq instance) =>
    <String, dynamic>{
      'action': instance.action,
      'rejectionReason': instance.rejectionReason,
    };
