import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_school.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_school.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_success.dart';

class ApiProviderSchool extends ApiProviderBase {
  Future<SchoolRes> createSchool(CreateSchoolReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.school,
      data: req.toJson(),
    ).then((response) => SchoolRes.fromJson(response.data ?? {}));
  }

  Future<SchoolListRes> getSchools({
    int? page,
    int? limit,
    String? search,
  }) async {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.school,
      query: query,
    ).then((response) => SchoolListRes.fromJson(response.data ?? {}));
  }

  Future<SchoolRes> getSchoolById(String id) async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.schoolById(id),
    ).then((response) => SchoolRes.fromJson(response.data ?? {}));
  }

  Future<SchoolRes> updateSchool(String id, UpdateSchoolReq req) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.schoolById(id),
      data: req.toJson(),
    ).then((response) => SchoolRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> deleteSchool(String id) async {
    return await ApiProviderBase.delete<Map<String, dynamic>>(
      MrSteamAPIs.schoolById(id),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }
}
