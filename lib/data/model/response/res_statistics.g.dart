// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticsAttendanceSummaryRes _$StatisticsAttendanceSummaryResFromJson(
  Map<String, dynamic> json,
) => StatisticsAttendanceSummaryRes(
  json['total'] as num,
  json['arrivedOrLate'] as num,
  json['pendingOrAbsent'] as num,
  json['attendanceRate'] as num,
);

Map<String, dynamic> _$StatisticsAttendanceSummaryResToJson(
  StatisticsAttendanceSummaryRes instance,
) => <String, dynamic>{
  'total': instance.total,
  'arrivedOrLate': instance.arrivedOrLate,
  'pendingOrAbsent': instance.pendingOrAbsent,
  'attendanceRate': instance.attendanceRate,
};

StatisticsAttendanceRes _$StatisticsAttendanceResFromJson(
  Map<String, dynamic> json,
) => StatisticsAttendanceRes(
  StatisticsAttendanceSummaryRes.fromJson(
    json['summary'] as Map<String, dynamic>,
  ),
  (json['byTutor'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  (json['bySchool'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$StatisticsAttendanceResToJson(
  StatisticsAttendanceRes instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'byTutor': instance.byTutor,
  'bySchool': instance.bySchool,
};

StatisticsLeaveSummaryRes _$StatisticsLeaveSummaryResFromJson(
  Map<String, dynamic> json,
) => StatisticsLeaveSummaryRes(
  json['total'] as num,
  json['pending'] as num,
  json['approved'] as num,
  json['rejected'] as num,
  json['approvalRate'] as num,
);

Map<String, dynamic> _$StatisticsLeaveSummaryResToJson(
  StatisticsLeaveSummaryRes instance,
) => <String, dynamic>{
  'total': instance.total,
  'pending': instance.pending,
  'approved': instance.approved,
  'rejected': instance.rejected,
  'approvalRate': instance.approvalRate,
};

StatisticsLeaveRes _$StatisticsLeaveResFromJson(Map<String, dynamic> json) =>
    StatisticsLeaveRes(
      StatisticsLeaveSummaryRes.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      (json['byStatus'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      (json['byTutor'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$StatisticsLeaveResToJson(StatisticsLeaveRes instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'byStatus': instance.byStatus,
      'byTutor': instance.byTutor,
    };

StatisticsCourseSummaryRes _$StatisticsCourseSummaryResFromJson(
  Map<String, dynamic> json,
) => StatisticsCourseSummaryRes(json['total'] as num);

Map<String, dynamic> _$StatisticsCourseSummaryResToJson(
  StatisticsCourseSummaryRes instance,
) => <String, dynamic>{'total': instance.total};

StatisticsCourseRes _$StatisticsCourseResFromJson(Map<String, dynamic> json) =>
    StatisticsCourseRes(
      StatisticsCourseSummaryRes.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      (json['byTutor'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      (json['bySchool'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$StatisticsCourseResToJson(
  StatisticsCourseRes instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'byTutor': instance.byTutor,
  'bySchool': instance.bySchool,
};

StatisticsUsersRes _$StatisticsUsersResFromJson(Map<String, dynamic> json) =>
    StatisticsUsersRes(json['totalTutors'] as num, json['totalStaff'] as num);

Map<String, dynamic> _$StatisticsUsersResToJson(StatisticsUsersRes instance) =>
    <String, dynamic>{
      'totalTutors': instance.totalTutors,
      'totalStaff': instance.totalStaff,
    };

StatisticsDashboardRes _$StatisticsDashboardResFromJson(
  Map<String, dynamic> json,
) => StatisticsDashboardRes(
  StatisticsAttendanceRes.fromJson(json['attendance'] as Map<String, dynamic>),
  StatisticsLeaveRes.fromJson(json['leave'] as Map<String, dynamic>),
  StatisticsCourseRes.fromJson(json['course'] as Map<String, dynamic>),
  StatisticsUsersRes.fromJson(json['users'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StatisticsDashboardResToJson(
  StatisticsDashboardRes instance,
) => <String, dynamic>{
  'attendance': instance.attendance,
  'leave': instance.leave,
  'course': instance.course,
  'users': instance.users,
};
