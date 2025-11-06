// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
// import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
// import 'package:dio_cache_interceptor/src/store/mem_cache_store.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker/talker.dart';

class DioClient {
  DioClient._();

  static Dio build({Talker? talker}) {
    final baseUrl = 'https://fyp-backend-zknqk6dfca-de.a.run.app';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // // Cache（可選）
    // dio.interceptors.add(
    //   DioCacheInterceptor(
    //     options: CacheOptions(
    //       store: MemCacheStore(),
    //       policy: CachePolicy.request, // 預設不強制用 cache
    //       hitCacheOnErrorExcept: [401, 403],
    //       maxStale: const Duration(days: 7),
    //     ),
    //   ),
    // );
    //
    // // 日誌
    // dio.interceptors.add(
    //   TalkerDioLogger(
    //     talker: talker ?? Talker(),
    //     settings: const TalkerDioLoggerSettings(
    //       printRequestData: true,
    //       printResponseData: true,
    //       printResponseMessage: true,
    //       requestHeader: true,
    //       responseHeader: false,
    //       error: true,
    //     ),
    //   ),
    // );

    return dio;
  }
}
