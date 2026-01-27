// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_leave.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveRes _$LeaveResFromJson(Map<String, dynamic> json) => LeaveRes(
  json['tutorId'] as String,
  json['reason'] as String,
  json['startDate'] as String,
  json['endDate'] as String,
  json['status'] as String,
  id: json['_id'] as String?,
  courseId: json['courseId'] as String?,
  approvedBy: json['approvedBy'] as String?,
  approvedAt: json['approvedAt'] as String?,
  rejectionReason: json['rejectionReason'] as String?,
  isDeleted: json['isDeleted'] as bool?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
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

LeaveListRes _$LeaveListResFromJson(Map<String, dynamic> json) => LeaveListRes(
  (json['items'] as List<dynamic>)
      .map((e) => LeaveRes.fromJson(e as Map<String, dynamic>))
      .toList(),
  (json['total'] as num).toInt(),
  (json['page'] as num).toInt(),
  (json['limit'] as num).toInt(),
  (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$LeaveListResToJson(LeaveListRes instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'pages': instance.pages,
    };
