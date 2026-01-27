// lib/core/network/api_provider_base.dart
import 'package:dio/dio.dart';
import 'package:fyp_mrsteam_web/core/util/app_preferences.dart';
import 'package:fyp_mrsteam_web/data/api/mrsteam_apis.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_auth.dart';
import 'package:retry/retry.dart';

typedef Json = Map<String, dynamic>;

class ApiProviderBase {
  static final _r = RetryOptions(
    maxAttempts: 3,
    delayFactor: const Duration(milliseconds: 300),
  );
  static Future<bool>? _refreshing;

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _requestWithRefresh(
      path,
      (dio) => _r.retry(
        () => dio.get<T>(
          path,
          queryParameters: query,
          options: options,
          cancelToken: cancelToken,
        ),
        retryIf: _shouldRetry,
      ),
      allowRefresh: _shouldAllowRefresh(path),
    );
  }

  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _requestWithRefresh(
      path,
      (dio) => dio.post<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      ),
      allowRefresh: _shouldAllowRefresh(path),
    );
  }

  static Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _requestWithRefresh(
      path,
      (dio) => dio.patch<T>(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      ),
      allowRefresh: _shouldAllowRefresh(path),
    );
  }

  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _requestWithRefresh(
      path,
      (dio) => dio.put<T>(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      ),
      allowRefresh: _shouldAllowRefresh(path),
    );
  }

  static Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _requestWithRefresh(
      path,
      (dio) => dio.delete<T>(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      ),
      allowRefresh: _shouldAllowRefresh(path),
    );
  }

  static Future<Response<T>> _requestWithRefresh<T>(
    String path,
    Future<Response<T>> Function(Dio dio) request, {
    required bool allowRefresh,
  }) async {
    try {
      final dio = defaultRequestBuilder();
      return await request(dio);
    } on DioException catch (e) {
      if (allowRefresh && _isUnauthorized(e)) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryDio = defaultRequestBuilder();
          return await request(retryDio);
        }
      }
      throw _mapDioError(e);
    }
  }

  static bool _shouldAllowRefresh(String path) {
    return path != MrSteamAPIs.refreshToken && path != MrSteamAPIs.login;
  }

  static bool _isUnauthorized(DioException e) =>
      (e.response?.statusCode ?? 0) == 401;

  static Future<bool> _refreshAccessToken() async {
    if (_refreshing != null) {
      return await _refreshing!;
    }

    final refreshToken = AppPreferences.getRefreshToken();
    final sessionId = AppPreferences.getSessionId();
    if (refreshToken.isEmpty || sessionId.isEmpty) {
      return false;
    }

    final refreshFuture = _performRefresh(refreshToken, sessionId);
    _refreshing = refreshFuture;
    try {
      final refreshed = await refreshFuture;
      if (!refreshed) {
        await AppPreferences.clear();
      }
      return refreshed;
    } finally {
      _refreshing = null;
    }
  }

  static Future<bool> _performRefresh(
    String refreshToken,
    String sessionId,
  ) async {
    try {
      final dio = defaultRequestBuilder(withAuthorization: false);
      final req = RefreshTokenReq(refreshToken, sessionId);
      final response = await dio.post<Map<String, dynamic>>(
        MrSteamAPIs.refreshToken,
        data: req.toJson(),
      );

      final data = response.data;
      if (data is! Map) return false;
      final map = data as Map<dynamic, dynamic>;

      final accessToken = map['access_token']?.toString() ?? '';
      final newRefreshToken = map['refresh_token']?.toString() ?? '';
      final newSessionId = map['session_id']?.toString() ?? '';

      if (accessToken.isEmpty) return false;
      await AppPreferences.setAccessToken(accessToken);
      if (newRefreshToken.isNotEmpty) {
        await AppPreferences.setRefreshToken(newRefreshToken);
      }
      if (newSessionId.isNotEmpty) {
        await AppPreferences.setSessionId(newSessionId);
      }
      return true;
    } catch (_) {
      return false;
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
    if (code == 422) {
      return ValidationException(_firstErrorMessage(e.response?.data));
    }
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
    final headers = {"Accept": "application/vnd.api+json"};
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
      responseType: responseType ?? ResponseType.json,
    );

    final dio = Dio(options);

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print("🧾 DioLog: $obj"),
      ),
    );

    return dio;
  }
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);
}

class ForbiddenException implements Exception {
  final String message;

  ForbiddenException(this.message);
}

class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);
}

class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);
}
