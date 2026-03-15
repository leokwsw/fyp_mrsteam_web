import 'package:dio/dio.dart';
import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_file.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_file.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_message.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_signed_url.dart';

class ApiProviderFiles extends ApiProviderBase {
  /// Encodes each path segment individually, preserving "/" separators.
  /// Uri.encodeComponent would wrongly encode "/" → "%2F" causing 404s.
  String _encodePath(String path) {
    return path
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
  }

  Future<FileUploadRes> uploadFile(UploadFileReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.uploadFile,
      data: req.toFormData(),
      options: Options(contentType: 'multipart/form-data'),
    ).then((response) => FileUploadRes.fromJson(response.data ?? {}));
  }

  Future<List<int>> downloadFile(String path) async {
    final encoded = _encodePath(path);
    return await ApiProviderBase.get<List<int>>(
      MrSteamAPIs.downloadFile(encoded),
      options: Options(responseType: ResponseType.bytes),
    ).then((response) => response.data ?? <int>[]);
  }

  Future<SignedUrlRes> getSignedUrl(String path) async {
    final encoded = _encodePath(path);
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.signedFileUrl(encoded),
    ).then((response) => SignedUrlRes.fromJson(response.data ?? {}));
  }

  Future<MessageRes> deleteFile(String path) async {
    final encoded = _encodePath(path);
    return await ApiProviderBase.delete<Map<String, dynamic>>(
      MrSteamAPIs.deleteFile(encoded),
    ).then((response) => MessageRes.fromJson(response.data ?? {}));
  }
}
