import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/core/network/api_envelope.dart';

void main() {
  group('ApiEnvelope', () {
    test('decodes a successful response', () {
      final envelope = ApiEnvelope.fromJson({
        'success': true,
        'data': {'id': '1'},
      }, (value) => (value as Map<String, dynamic>)['id'] as String);
      expect(envelope.data, '1');
    });

    test('exposes a stable backend error code', () {
      expect(
        () => ApiEnvelope<void>.fromJson({
          'success': false,
          'error': {'code': 'PHONE_EXISTS', 'message': 'Phone exists'},
        }, (_) {}),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'PHONE_EXISTS',
          ),
        ),
      );
    });
  });
}
