import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_auth.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_login.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_logout.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_common_message.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_login.dart';

class ApiProviderAuth extends ApiProviderBase {
  Future<LoginRes> login(LoginReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.login,
      data: req.toJson(),
    ).then((response) => LoginRes.fromJson(response.data ?? {}));
  }

  Future<CommonMessage> logout(LogoutReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.logout,
      data: req.toJson(),
    ).then((response) => CommonMessage.fromJson(response.data ?? {}));
  }

  Future<LoginRes> refreshToken(RefreshTokenReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.refreshToken,
      data: req.toJson(),
    ).then((response) => LoginRes.fromJson(response.data ?? {}));
  }

  Future<CommonMessage> validateToken() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.validateToken,
    ).then((response) => CommonMessage.fromJson(response.data ?? {}));
  }

  Future<CommonMessage> changePassword(ChangePasswordReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.changePassword,
      data: req.toJson(),
    ).then((response) => CommonMessage.fromJson(response.data ?? {}));
  }
}
