import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:konush/src/core/config/app_config.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/network/auth_interceptor.dart';
import 'package:konush/src/core/storage/token_storage.dart';
import 'package:konush/src/features/auth/data/auth_remote_data_source.dart';
import 'package:konush/src/features/auth/data/auth_repository_impl.dart';
import 'package:konush/src/features/auth/domain/auth_repository.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_flow_cubit.dart';
import 'package:konush/src/features/listings/data/listings_remote_data_source.dart';
import 'package:konush/src/features/listings/data/listings_repository_impl.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/cubit/listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/my_listings_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => TokenStorage(sl()));
  sl.registerLazySingleton(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(AuthInterceptor(dio, sl()));
    return dio;
  });
  sl.registerLazySingleton(() => ApiClient(sl()));

  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerFactory(() => AuthCubit(sl()));
  sl.registerFactory(() => AuthFlowCubit(sl()));

  sl.registerLazySingleton(() => ListingsRemoteDataSource(sl()));
  sl.registerLazySingleton<ListingsRepository>(
    () => ListingsRepositoryImpl(sl()),
  );
  sl.registerFactory(() => ListingsCubit(sl()));
  sl.registerFactory(() => FavoritesCubit(sl(), sl(), sl()));
  sl.registerFactory(() => MyListingsCubit(sl()));
}
