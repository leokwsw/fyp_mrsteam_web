import 'package:fyp_mrsteam_web/data/api/api_provider_auth.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_auth.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_login.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_logout.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_common_message.dart';

import '../model/response/res_login.dart';

class AuthRepo {
  final ApiProviderAuth api;

  AuthRepo(this.api);

  Future<LoginRes> login(String username, String password) async {
    return await api.login(LoginReq(username, password, role: 'tutor')).then((
      res,
    ) {
      return res;
    });
  }

  Future<CommonMessage> logout(String sessionId) async {
    return await api.logout(LogoutReq(sessionId)).then((res) => res);
  }

  Future<LoginRes> refreshToken(String refreshToken, String sessionId) async {
    return await api
        .refreshToken(RefreshTokenReq(refreshToken, sessionId))
        .then((res) => res);
  }

  Future<CommonMessage> validateToken() async {
    return await api.validateToken().then((res) => res);
  }

  Future<CommonMessage> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    return await api
        .changePassword(ChangePasswordReq(oldPassword, newPassword))
        .then((res) => res);
  }
}
