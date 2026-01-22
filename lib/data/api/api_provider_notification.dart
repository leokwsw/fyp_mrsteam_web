import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_notification.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_message.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_notification.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_success.dart';

class ApiProviderNotification extends ApiProviderBase {
  Future<MessageRes> registerDeviceToken(RegisterDeviceTokenReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.registerDeviceToken,
      data: req.toJson(),
    ).then((response) => MessageRes.fromJson(response.data ?? {}));
  }

  Future<NotificationListRes> getNotifications({
    int? page,
    int? limit,
    String? isRead,
    String? type,
  }) async {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (isRead != null) 'isRead': isRead,
      if (type != null) 'type': type,
    };
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.notification,
      query: query,
    ).then((response) => NotificationListRes.fromJson(response.data ?? {}));
  }

  Future<UnreadCountRes> getUnreadCount() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.notificationUnreadCount,
    ).then((response) => UnreadCountRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> markAsRead(String id) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.notificationRead(id),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> markAllAsRead() async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.notificationReadAll,
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }
}
