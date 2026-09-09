import 'package:konush/src/core/error/app_exception.dart';

class ApiEnvelope<T> {
  const ApiEnvelope({required this.data, this.meta});

  final T data;
  final Map<String, dynamic>? meta;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) decode,
  ) {
    if (json['success'] != true) {
      final error = json['error'] as Map<String, dynamic>? ?? const {};
      throw AppException(
        error['message'] as String? ?? 'Неизвестная ошибка сервера',
        code: error['code'] as String?,
        details: error['details'],
      );
    }
    return ApiEnvelope(
      data: decode(json['data']),
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}
