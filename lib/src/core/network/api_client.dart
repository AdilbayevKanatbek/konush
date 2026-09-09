import 'package:dio/dio.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/core/network/api_envelope.dart';

class ApiClient {
  const ApiClient(this._dio);
  final Dio _dio;

  Future<ApiEnvelope<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? json) decode,
  }) => _request(
    () => _dio.get<Object?>(path, queryParameters: queryParameters),
    decode,
  );

  Future<ApiEnvelope<T>> post<T>(
    String path, {
    Object? data,
    required T Function(Object? json) decode,
  }) => _request(() => _dio.post<Object?>(path, data: data), decode);

  Future<ApiEnvelope<T>> put<T>(
    String path, {
    Object? data,
    required T Function(Object? json) decode,
  }) => _request(() => _dio.put<Object?>(path, data: data), decode);

  Future<ApiEnvelope<T>> delete<T>(
    String path, {
    Object? data,
    required T Function(Object? json) decode,
  }) => _request(() => _dio.delete<Object?>(path, data: data), decode);

  Future<ApiEnvelope<T>> _request<T>(
    Future<Response<Object?>> Function() request,
    T Function(Object? json) decode,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AppException('Некорректный ответ сервера');
      }
      return ApiEnvelope.fromJson(body, decode);
    } on DioException catch (error) {
      final body = error.response?.data;
      final envelope = body is Map<String, dynamic> ? body : null;
      final apiError = envelope?['error'] as Map<String, dynamic>?;
      throw AppException(
        apiError?['message'] as String? ?? 'Не удалось связаться с сервером',
        code: apiError?['code'] as String?,
        details: apiError?['details'],
        statusCode: error.response?.statusCode,
      );
    }
  }
}
