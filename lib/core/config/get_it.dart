import 'package:fyp_mrsteam_web/core/router/router_app.dart';
import 'package:fyp_mrsteam_web/data/api/api_provider_auth.dart';
import 'package:fyp_mrsteam_web/data/repo/repo_auth.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> initGetIt() async {
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());

  // Config / Env
  // sl.registerLazySingleton<AppConfig>(() => AppConfig.fromEnv());
  //
  // // Network
  // sl.registerLazySingleton<Dio>(() {
  //   final config = sl<AppConfig>();
  //   return Dio(BaseOptions(baseUrl: config.apiBase));
  // });
  //
  // // Data sources & Repos
  // sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(sl<Dio>()));
  // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl<AuthRemoteDataSource>()));
  //
  getIt.registerLazySingleton<ApiProviderAuth>(() => ApiProviderAuth());
  getIt.registerLazySingleton<AuthRepo>(() => AuthRepo(getIt<ApiProviderAuth>()));

  // sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  //
  // // Blocs / Cubits（工廠，確保每次要新實例）
  // sl.registerFactory(() => LoginBloc(sl<LoginUseCase>()));
  // sl.registerFactory(() => RegisterBloc(sl<RegisterUseCase>()));
  //
  // // 需要 async 初始（例如 SharedPreferences、HydratedStorage）
  // sl.registerSingletonAsync<SharedPreferences>(() async => await SharedPreferences.getInstance());
  await getIt.allReady(); // 等待所有 async 服務 ready
}
