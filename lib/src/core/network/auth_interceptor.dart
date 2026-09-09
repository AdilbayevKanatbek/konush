import 'dart:async';

import 'package:dio/dio.dart';
import 'package:konush/src/core/config/app_config.dart';
import 'package:konush/src/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;
  Future<TokenPair?>? _refreshing;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra['retried'] == true ||
        request.path.endsWith('/auth/refresh')) {
      return handler.next(err);
    }

    final pair = await (_refreshing ??= _refresh()).whenComplete(
      () => _refreshing = null,
    );
    if (pair == null) return handler.next(err);

    request.extra['retried'] = true;
    request.headers['Authorization'] = 'Bearer ${pair.accessToken}';
    try {
      handler.resolve(await _dio.fetch<Object?>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<TokenPair?> _refresh() async {
    final refreshToken = await _tokens.refreshToken;
    if (refreshToken == null) return null;
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final pair = TokenPair(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        expiresIn: data['expires_in'] as int? ?? 900,
      );
      await _tokens.save(pair);
      return pair;
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }
}
