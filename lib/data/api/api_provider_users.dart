import 'package:dio/dio.dart';
import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_user.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_message.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_success.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_user.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_users_list.dart';

class ApiProviderUsers extends ApiProviderBase {
  Future<UserResponse> createUser(CreateUserReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.users,
      data: req.toJson(),
    ).then((response) => UserResponse.fromJson(response.data ?? {}));
  }

  Future<UsersListRes> getUsers({
    int? page,
    int? limit,
    String? search,
    String? role,
    String? isActive,
    String? sortBy,
    String? sortOrder,
  }) async {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
      if (role != null) 'role': role,
      if (isActive != null) 'isActive': isActive,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.users,
      query: query,
    ).then((response) => UsersListRes.fromJson(response.data ?? {}));
  }

  Future<UserResponse> getProfile() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.profile,
    ).then((response) => UserResponse.fromJson(response.data ?? {}));
  }

  Future<Response<dynamic>> getProfileRaw() async {
    return await ApiProviderBase.get<dynamic>(MrSteamAPIs.profile);
  }

  Future<UserResponse> getUserById(String id) async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.userById(id),
    ).then((response) => UserResponse.fromJson(response.data ?? {}));
  }

  Future<UserResponse> updateUserById(String id, UpdateUserReq req) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.userById(id),
      data: req.toJson(),
    ).then((response) => UserResponse.fromJson(response.data ?? {}));
  }

  Future<UserResponse> updateUser(UpdateUserReq req) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.userSelf,
      data: req.toJson(),
    ).then((response) => UserResponse.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> deleteUser(String id) async {
    return await ApiProviderBase.delete<Map<String, dynamic>>(
      MrSteamAPIs.userById(id),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> updateUserActiveStatus(
    String id,
    ActiveUserReq req,
  ) async {
    return await ApiProviderBase.put<Map<String, dynamic>>(
      MrSteamAPIs.userActive(id),
      data: req.toJson(),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }

  Future<MessageRes> resetPassword(String id, ResetPasswordReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.userResetPassword(id),
      data: req.toJson(),
    ).then((response) => MessageRes.fromJson(response.data ?? {}));
  }

  /// 需帶後端要求的 `x-force-reset-key` 標頭。
  Future<MessageRes> forceResetPassword(
    String id,
    ResetPasswordReq req, {
    required String forceResetKey,
  }) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.userForceResetPassword(id),
      data: req.toJson(),
      options: Options(
        headers: <String, dynamic>{'x-force-reset-key': forceResetKey},
      ),
    ).then((response) => MessageRes.fromJson(response.data ?? {}));
  }
}
