import 'dart:async';

import 'package:dio/dio.dart';
import 'package:konush/src/core/config/app_config.dart';
import 'package:konush/src/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokens, {Dio? refreshClient})
    : _refreshClient = refreshClient;
  final Dio? _refreshClient;

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

    TokenPair? pair;
    try {
      pair = await (_refreshing ??= _refresh()).whenComplete(() {
        _refreshing = null;
      });
    } on DioException catch (error) {
      return handler.next(
        DioException(
          requestOptions: request,
          type: error.type,
          error: error.error,
          response: error.response,
          message: error.message,
        ),
      );
    }
    if (pair == null) return handler.next(err);

    request.extra['retried'] = true;
    request.headers['Authorization'] = 'Bearer ${pair.accessToken}';
    if (request.data is FormData) {
      request.data = (request.data as FormData).clone();
    }
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
      final refreshDio =
          _refreshClient ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );
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
      if (await _tokens.refreshToken != refreshToken) return null;
      await _tokens.save(pair);
      return pair;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        if (await _tokens.refreshToken == refreshToken) await _tokens.clear();
      }
      if (error.response?.statusCode != 401 &&
          error.response?.statusCode != 403) {
        rethrow;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
