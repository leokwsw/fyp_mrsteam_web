import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_notification.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_notification_template.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_success.dart';

class ApiProviderNotificationTemplate extends ApiProviderBase {
  Future<NotificationTemplateRes> createTemplate(
    CreateNotificationTemplateReq req,
  ) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.notificationTemplate,
      data: req.toJson(),
    ).then((response) => NotificationTemplateRes.fromJson(response.data ?? {}));
  }

  Future<NotificationTemplateListRes> getAllTemplates() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.notificationTemplate,
    ).then(
      (response) => NotificationTemplateListRes.fromJson(response.data ?? {}),
    );
  }

  Future<NotificationTemplateListRes> getActiveTemplates() async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.notificationTemplateActive,
    ).then(
      (response) => NotificationTemplateListRes.fromJson(response.data ?? {}),
    );
  }

  Future<NotificationTemplateRes> getTemplateById(String id) async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.notificationTemplateById(id),
    ).then((response) => NotificationTemplateRes.fromJson(response.data ?? {}));
  }

  Future<NotificationTemplateRes> updateTemplate(
    String id,
    UpdateNotificationTemplateReq req,
  ) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.notificationTemplateById(id),
      data: req.toJson(),
    ).then((response) => NotificationTemplateRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> deleteTemplate(String id) async {
    return await ApiProviderBase.delete<Map<String, dynamic>>(
      MrSteamAPIs.notificationTemplateById(id),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }
}
