import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:fyp_mrsteam_web/data/api/api_provider_base.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_course.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_course.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_signed_url.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_success.dart';

class ApiProviderCourse extends ApiProviderBase {
  Future<CourseRes> createCourse(CreateCourseReq req) async {
    return await ApiProviderBase.post<Map<String, dynamic>>(
      MrSteamAPIs.course,
      data: req.toJson(),
    ).then((response) => CourseRes.fromJson(response.data ?? {}));
  }

  Future<CourseListRes> getCourses({
    int? page,
    int? limit,
    String? search,
    String? tutorId,
    String? schoolId,
  }) async {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
      if (tutorId != null) 'tutorId': tutorId,
      if (schoolId != null) 'schoolId': schoolId,
    };

    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.course,
      query: query,
    ).then((response) {
      debugPrint('=== getCourses RAW response ===');
      debugPrint(response.data.toString());
      return CourseListRes.fromJson(response.data ?? {});
    });
  }

  Future<CourseRes> getCourseById(String id) async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.courseById(id),
    ).then((response) => CourseRes.fromJson(response.data ?? {}));
  }

  Future<CourseRes> updateCourse(String id, UpdateCourseReq req) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.courseById(id),
      data: req.toJson(),
    ).then((response) => CourseRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> enableCourse(String id) async {
    return await ApiProviderBase.patch<Map<String, dynamic>>(
      MrSteamAPIs.courseStatus(id),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }

  Future<SuccessRes> disableCourse(String id) async {
    return await ApiProviderBase.delete<Map<String, dynamic>>(
      MrSteamAPIs.courseStatus(id),
    ).then((response) => SuccessRes.fromJson(response.data ?? {}));
  }

  Future<CourseFilesRes> getCourseFiles(String id) async {
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.courseFiles(id),
    ).then((response) => CourseFilesRes.fromJson(response.data ?? {}));
  }

  Future<List<int>> downloadCourseFile(String id, num fileIndex) async {
    return await ApiProviderBase.get<List<int>>(
      MrSteamAPIs.courseFileDownload(id, fileIndex),
      options: Options(responseType: ResponseType.bytes),
    ).then((response) => response.data ?? <int>[]);
  }

  Future<SignedUrlRes> getCourseFileSignedUrl(
    String id,
    num fileIndex, {
    required num expiresIn,
  }) async {
    final query = <String, dynamic>{'expiresIn': expiresIn};
    return await ApiProviderBase.get<Map<String, dynamic>>(
      MrSteamAPIs.courseFileSignedUrl(id, fileIndex),
      query: query,
    ).then((response) => SignedUrlRes.fromJson(response.data ?? {}));
  }
}