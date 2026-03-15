import 'package:dio/dio.dart';
import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_attendance.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_attendance.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_success.dart';

class ApiProviderAttendance extends ApiProviderBase {
  Future<AttendanceListRes> getAttendances({
    int? page,
    int? limit,
    String? courseId,
    String? tutorId,
    String? schoolId,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (courseId != null && courseId.trim().isNotEmpty) 'courseId': courseId.trim(),
      if (tutorId != null && tutorId.trim().isNotEmpty) 'tutorId': tutorId.trim(),
      if (schoolId != null && schoolId.trim().isNotEmpty) 'schoolId': schoolId.trim(),
      if (startDate != null && startDate.trim().isNotEmpty) 'startDate': startDate.trim(),
      if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate.trim(),
    };

    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.attendance,
      query: query,
    ).then((response) => AttendanceListRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> checkIn(AttendanceCheckInReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.attendance,
      data: req.toFormData(),
      options: Options(contentType: 'multipart/form-data'),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }

  Future<AttendanceRes> getAttendanceById(String id) async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.attendanceById(id),
    ).then((response) => AttendanceRes.fromJson(response.data ?? {}));
  }

  Future<List<int>> exportAttendances({
  String? courseId,
  String? tutorId,
  String? schoolId,
  String? startDate,
  String? endDate,
  String format = 'excel', // backend: csv | excel
}) async {
  final normalizedFormat =
      format.toLowerCase() == 'xlsx' ? 'excel' : format.toLowerCase();

  final query = <String, dynamic>{
    'format': normalizedFormat,
    if (courseId != null && courseId.trim().isNotEmpty) 'courseId': courseId.trim(),
    if (tutorId != null && tutorId.trim().isNotEmpty) 'tutorId': tutorId.trim(),
    if (schoolId != null && schoolId.trim().isNotEmpty) 'schoolId': schoolId.trim(),
    if (startDate != null && startDate.trim().isNotEmpty) 'startDate': startDate.trim(),
    if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate.trim(),
  };

  return await ApiProviderBase.get<List<int>>(
    MrSteamAPIs.attendanceExport,
    query: query,
    options: Options(responseType: ResponseType.bytes),
  ).then((response) => response.data ?? <int>[]);
  }
}