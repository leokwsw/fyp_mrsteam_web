// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_leave.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveRes _$LeaveResFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LeaveRes',
  json,
  ($checkedConvert) {
    final val = LeaveRes(
      $checkedConvert('tutorId', (v) => v as String),
      $checkedConvert('reason', (v) => v as String),
      $checkedConvert('startDate', (v) => v as String),
      $checkedConvert('endDate', (v) => v as String),
      $checkedConvert('status', (v) => v as String),
      id: $checkedConvert('_id', (v) => v as String?),
      courseId: $checkedConvert('courseId', (v) => v as String?),
      approvedBy: $checkedConvert('approvedBy', (v) => v as String?),
      approvedAt: $checkedConvert('approvedAt', (v) => v as String?),
      rejectionReason: $checkedConvert('rejectionReason', (v) => v as String?),
      isDeleted: $checkedConvert('isDeleted', (v) => v as bool?),
      createdAt: $checkedConvert('createdAt', (v) => v as String?),
      updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'id': '_id'},
);

Map<String, dynamic> _$LeaveResToJson(LeaveRes instance) => <String, dynamic>{
  '_id': instance.id,
  'tutorId': instance.tutorId,
  'courseId': instance.courseId,
  'reason': instance.reason,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'status': instance.status,
  'approvedBy': instance.approvedBy,
  'approvedAt': instance.approvedAt,
  'rejectionReason': instance.rejectionReason,
  'isDeleted': instance.isDeleted,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

LeaveListRes _$LeaveListResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LeaveListRes', json, ($checkedConvert) {
      final val = LeaveListRes(
        $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LeaveRes.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        $checkedConvert('total', (v) => (v as num).toInt()),
        $checkedConvert('page', (v) => (v as num).toInt()),
        $checkedConvert('limit', (v) => (v as num).toInt()),
        $checkedConvert('pages', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$LeaveListResToJson(LeaveListRes instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'pages': instance.pages,
    };
