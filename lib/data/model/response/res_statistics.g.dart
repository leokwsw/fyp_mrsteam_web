// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticsAttendanceSummaryRes _$StatisticsAttendanceSummaryResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsAttendanceSummaryRes', json, ($checkedConvert) {
  final val = StatisticsAttendanceSummaryRes(
    $checkedConvert('total', (v) => v as num),
    $checkedConvert('checked', (v) => v as num),
    $checkedConvert('unchecked', (v) => v as num),
    $checkedConvert('attendanceRate', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$StatisticsAttendanceSummaryResToJson(
  StatisticsAttendanceSummaryRes instance,
) => <String, dynamic>{
  'total': instance.total,
  'checked': instance.checked,
  'unchecked': instance.unchecked,
  'attendanceRate': instance.attendanceRate,
};

StatisticsAttendanceRes _$StatisticsAttendanceResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsAttendanceRes', json, ($checkedConvert) {
  final val = StatisticsAttendanceRes(
    $checkedConvert(
      'summary',
      (v) => StatisticsAttendanceSummaryRes.fromJson(v as Map<String, dynamic>),
    ),
    $checkedConvert(
      'byTutor',
      (v) =>
          (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    ),
    $checkedConvert(
      'bySchool',
      (v) =>
          (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$StatisticsAttendanceResToJson(
  StatisticsAttendanceRes instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'byTutor': instance.byTutor,
  'bySchool': instance.bySchool,
};

StatisticsLeaveSummaryRes _$StatisticsLeaveSummaryResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsLeaveSummaryRes', json, ($checkedConvert) {
  final val = StatisticsLeaveSummaryRes(
    $checkedConvert('total', (v) => v as num),
    $checkedConvert('pending', (v) => v as num),
    $checkedConvert('approved', (v) => v as num),
    $checkedConvert('rejected', (v) => v as num),
    $checkedConvert('approvalRate', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$StatisticsLeaveSummaryResToJson(
  StatisticsLeaveSummaryRes instance,
) => <String, dynamic>{
  'total': instance.total,
  'pending': instance.pending,
  'approved': instance.approved,
  'rejected': instance.rejected,
  'approvalRate': instance.approvalRate,
};

StatisticsLeaveRes _$StatisticsLeaveResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsLeaveRes', json, ($checkedConvert) {
  final val = StatisticsLeaveRes(
    $checkedConvert(
      'summary',
      (v) => StatisticsLeaveSummaryRes.fromJson(v as Map<String, dynamic>),
    ),
    $checkedConvert(
      'byStatus',
      (v) =>
          (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    ),
    $checkedConvert(
      'byTutor',
      (v) =>
          (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$StatisticsLeaveResToJson(StatisticsLeaveRes instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'byStatus': instance.byStatus,
      'byTutor': instance.byTutor,
    };

StatisticsCourseSummaryRes _$StatisticsCourseSummaryResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsCourseSummaryRes', json, ($checkedConvert) {
  final val = StatisticsCourseSummaryRes(
    $checkedConvert('total', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$StatisticsCourseSummaryResToJson(
  StatisticsCourseSummaryRes instance,
) => <String, dynamic>{'total': instance.total};

StatisticsCourseRes _$StatisticsCourseResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsCourseRes', json, ($checkedConvert) {
  final val = StatisticsCourseRes(
    $checkedConvert(
      'summary',
      (v) => StatisticsCourseSummaryRes.fromJson(v as Map<String, dynamic>),
    ),
    $checkedConvert(
      'byTutor',
      (v) =>
          (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    ),
    $checkedConvert(
      'bySchool',
      (v) =>
          (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$StatisticsCourseResToJson(
  StatisticsCourseRes instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'byTutor': instance.byTutor,
  'bySchool': instance.bySchool,
};

StatisticsUsersRes _$StatisticsUsersResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StatisticsUsersRes', json, ($checkedConvert) {
      final val = StatisticsUsersRes(
        $checkedConvert('totalTutors', (v) => v as num),
        $checkedConvert('totalStaff', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$StatisticsUsersResToJson(StatisticsUsersRes instance) =>
    <String, dynamic>{
      'totalTutors': instance.totalTutors,
      'totalStaff': instance.totalStaff,
    };

StatisticsDashboardRes _$StatisticsDashboardResFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StatisticsDashboardRes', json, ($checkedConvert) {
  final val = StatisticsDashboardRes(
    $checkedConvert(
      'attendance',
      (v) => StatisticsAttendanceRes.fromJson(v as Map<String, dynamic>),
    ),
    $checkedConvert(
      'leave',
      (v) => StatisticsLeaveRes.fromJson(v as Map<String, dynamic>),
    ),
    $checkedConvert(
      'course',
      (v) => StatisticsCourseRes.fromJson(v as Map<String, dynamic>),
    ),
    $checkedConvert(
      'users',
      (v) => StatisticsUsersRes.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$StatisticsDashboardResToJson(
  StatisticsDashboardRes instance,
) => <String, dynamic>{
  'attendance': instance.attendance,
  'leave': instance.leave,
  'course': instance.course,
  'users': instance.users,
};
