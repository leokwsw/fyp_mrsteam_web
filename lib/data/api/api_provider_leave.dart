import 'package:dio/dio.dart';
import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_leave.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_leave.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_success.dart';

class ApiProviderLeave extends ApiProviderBase {
  Future<LeaveRes> createLeave(CreateLeaveReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.leave,
      data: req.toJson(),
    ).then((response) => LeaveRes.fromJson(response.data ?? {}));
  }

  Future<LeaveListRes> getLeaves({
    int? page,
    int? limit,
    String? tutorId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (tutorId != null) 'tutorId': tutorId,
      if (status != null) 'status': status,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.leave,
      query: query,
    ).then((response) => LeaveListRes.fromJson(response.data ?? {}));
  }

  Future<LeaveRes> getLeaveById(String id) async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.leaveById(id),
    ).then((response) => LeaveRes.fromJson(response.data ?? {}));
  }

  Future<LeaveRes> updateLeave(String id, UpdateLeaveReq req) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.leaveById(id),
      data: req.toJson(),
    ).then((response) => LeaveRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> deleteLeave(String id) async {
    return await ApiProviderBase.delete<Map<String, dynamic>>(
      MrSteamAPIs.leaveById(id),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }

  Future<LeaveRes> approveLeave(String id, ApproveLeaveReq req) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.leaveApprove(id),
      data: req.toJson(),
    ).then((response) => LeaveRes.fromJson(response.data ?? {}));
  }

  Future<List<int>> exportLeaves({
    int? page,
    int? limit,
    String? tutorId,
    String? status,
    String? startDate,
    String? endDate,
    required String format,
  }) async {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (tutorId != null) 'tutorId': tutorId,
      if (status != null) 'status': status,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'format': format,
    };
    return await ApiProviderBase.get<List<int>>(
      MrSteamAPIs.leaveExport,
      query: query,
      options: Options(responseType: ResponseType.bytes),
    ).then((response) => response.data ?? <int>[]);
  }
}
