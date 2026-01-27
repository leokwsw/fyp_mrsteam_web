import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_raw_json.dart';

class ApiProviderSystem extends ApiProviderBase {
  Future<RawJsonRes> getMetrics() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.systemMetrics,
    ).then((response) => RawJsonRes.fromJson(response.data ?? {}));
  }

  Future<RawJsonRes> getLogs({
    String? startDate,
    String? endDate,
    String? path,
    String? statusCode,
    String? method,
    int? limit,
    int? page,
  }) async {
    final query = <String, dynamic>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (path != null) 'path': path,
      if (statusCode != null) 'statusCode': statusCode,
      if (method != null) 'method': method,
      if (limit != null) 'limit': limit,
      if (page != null) 'page': page,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.systemLogs,
      query: query,
    ).then((response) => RawJsonRes.fromJson(response.data ?? {}));
  }

  Future<RawJsonRes> getStats() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.systemStats,
    ).then((response) => RawJsonRes.fromJson(response.data ?? {}));
  }
}
