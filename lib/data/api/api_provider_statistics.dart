import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_statistics.dart';

class ApiProviderStatistics extends ApiProviderBase {
  Future<StatisticsDashboardRes> getDashboardStatistics({
    required String tutorId,
    required String schoolId,
    required String startDate,
    required String endDate,
  }) async {
    final query = <String, dynamic>{
      'tutorId': tutorId,
      'schoolId': schoolId,
      'startDate': startDate,
      'endDate': endDate,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.statisticsDashboard,
      query: query,
    ).then((response) => StatisticsDashboardRes.fromJson(response.data ?? {}));
  }

  Future<StatisticsAttendanceRes> getAttendanceStatistics({
    required String tutorId,
    required String schoolId,
    required String startDate,
    required String endDate,
  }) async {
    final query = <String, dynamic>{
      'tutorId': tutorId,
      'schoolId': schoolId,
      'startDate': startDate,
      'endDate': endDate,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.statisticsAttendance,
      query: query,
    ).then((response) => StatisticsAttendanceRes.fromJson(response.data ?? {}));
  }

  Future<StatisticsLeaveRes> getLeaveStatistics({
    required String tutorId,
    required String startDate,
    required String endDate,
  }) async {
    final query = <String, dynamic>{
      'tutorId': tutorId,
      'startDate': startDate,
      'endDate': endDate,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.statisticsLeave,
      query: query,
    ).then((response) => StatisticsLeaveRes.fromJson(response.data ?? {}));
  }

  Future<StatisticsCourseRes> getCourseStatistics({
    required String tutorId,
    required String schoolId,
  }) async {
    final query = <String, dynamic>{'tutorId': tutorId, 'schoolId': schoolId};
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.statisticsCourse,
      query: query,
    ).then((response) => StatisticsCourseRes.fromJson(response.data ?? {}));
  }
}
