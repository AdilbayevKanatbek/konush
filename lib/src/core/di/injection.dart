import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:konush/src/features/chat/domain/chat_models.dart';
import 'package:konush/src/features/chat/domain/chat_repository.dart';
import 'package:konush/src/features/chat/data/chat_repository_impl.dart';
import 'package:konush/src/features/chat/data/chat_socket.dart';
import 'package:konush/src/features/chat/presentation/chat_cubit.dart';
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
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerFactory<ChatRealtime>(
    () => ChatSocket(
      url: Uri.parse(AppConfig.webSocketUrl),
      tokenProvider: (refresh) async {
        var token = await sl<TokenStorage>().accessToken;
        if (token == null) return null;
        bool expiresSoon = false;
        try {
          final payload =
              jsonDecode(
                    utf8.decode(
                      base64Url.decode(
                        base64Url.normalize(token.split('.')[1]),
                      ),
                    ),
                  )
                  as Map<String, dynamic>;
          final exp = payload['exp'] as num?;
          expiresSoon =
              exp != null &&
              exp * 1000 < DateTime.now().millisecondsSinceEpoch + 30000;
        } catch (_) {
          expiresSoon = true;
        }
        if (refresh || expiresSoon) {
          await sl<AuthRepository>().getProfile();
          token = await sl<TokenStorage>().accessToken;
        }
        return token;
      },
    ),
  );
  sl.registerFactory(() => ChatCubit(sl(), sl()));
}
