// lib/core/network/api_provider_base.dart
import 'package:dio/dio.dart';
import 'package:fyp_mrsteam_web/core/util/app_preferences.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:retry/retry.dart';

typedef Json = Map<String, dynamic>;

class ApiProviderBase {

  static final _r = RetryOptions(
    maxAttempts: 3,
    delayFactor: const Duration(milliseconds: 300),
  );

  static Future<Response<T>> get<T>(
      String path, {
        Map<String, dynamic>? query,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final dio = defaultRequestBuilder();
      return await _r.retry(
            () => dio.get<T>(
          path,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken,
        ),
        retryIf: _shouldRetry,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  static Future<Response<T>> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? query,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final dio = defaultRequestBuilder();
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  static Future<Response<T>> patch<T>(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final dio = defaultRequestBuilder();
      return await dio.patch<T>(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  static Future<Response<T>> delete<T>(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final dio = defaultRequestBuilder();
      return await dio.delete<T>(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  static bool _shouldRetry(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          (e.response?.statusCode ?? 0) >= 500;
    }
    return false;
  }

  static Exception _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    final msg = e.message ?? 'Network error';
    if (code == 401) return UnauthorizedException(msg);
    if (code == 403) return ForbiddenException(msg);
    if (code == 404) return NotFoundException(msg);
    if (code == 422) return ValidationException(_firstErrorMessage(e.response?.data));
    return NetworkException(msg);
  }

  static String _firstErrorMessage(dynamic data) {
    // 後端 validation 可能是 { errors: { email: ["..."] } }
    try {
      if (data is Map && data['errors'] is Map) {
        final first = (data['errors'] as Map).values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (data is Map && data['message'] is String) return data['message'];
    } catch (_) {}
    return 'Validation error';
  }

  static const kConnectTimeout = Duration(seconds: 10); // 10s
  static const kReadTimeout = Duration(seconds: 60); // 60s
  static const kSendTimeout = Duration(seconds: 60); // 60s

  static Dio defaultRequestBuilder({
    String customUrl = "",
    String contentType = "application/json",
    bool withHeader = true,
    Map<String, String>? appendHeader,
    bool withAuthorization = true,
    bool withSlash = true,
    bool customUrlWithApiV1 = false,
    bool isPublicApi = false,
    String path = "",
    String? proxyInfoUri,
    ResponseType? responseType,
  }) {
    final headers = {
      "Accept": "application/vnd.api+json",
    };
    if (appendHeader != null) {
      headers.addAll(appendHeader);
    }
    final userToken = AppPreferences.getAccessToken();
    if (withAuthorization && userToken.isNotEmpty) {
      headers["Authorization"] = "bearer ${AppPreferences.getAccessToken()}";
    }

    BaseOptions options = BaseOptions(
        baseUrl: MrSteamAPIs.baseUrl,
        connectTimeout: kConnectTimeout,
        receiveTimeout: kReadTimeout,
        sendTimeout: kSendTimeout,
        contentType: contentType,
        headers: withHeader ? headers : null,
        responseType: responseType ?? ResponseType.json);

    final dio = Dio(options);

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
          logPrint: (obj) => print("🧾 DioLog: $obj"),
      )
    );

    return dio;
  }
}

class NetworkException implements Exception { final String message; NetworkException(this.message); }
class UnauthorizedException implements Exception { final String message; UnauthorizedException(this.message); }
class ForbiddenException implements Exception { final String message; ForbiddenException(this.message); }
class NotFoundException implements Exception { final String message; NotFoundException(this.message); }
class ValidationException implements Exception { final String message; ValidationException(this.message); }
