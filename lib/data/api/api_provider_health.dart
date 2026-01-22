import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_health.dart';

class ApiProviderHealth extends ApiProviderBase {
  Future<HealthRes> check() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.health,
    ).then((response) => HealthRes.fromJson(response.data ?? {}));
  }
}
