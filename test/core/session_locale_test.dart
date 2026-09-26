import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konush/l10n/locale_cubit.dart';
import 'package:konush/l10n/generated/app_localizations.dart';
import 'package:konush/l10n/source_messages.dart';
import 'package:konush/src/core/network/auth_interceptor.dart';
import 'package:konush/src/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old',
      'refresh_token': 'refresh',
      'preferred_locale': 'ky',
    }),
  );
  test(
    'locale defaults to Russian, restores Kyrgyz and persists user selection',
    () async {
      final locale = LocaleCubit(const FlutterSecureStorage());
      expect(locale.state.languageCode, 'ru');
      await locale.restore();
      expect(locale.state.languageCode, 'ky');
      await locale.select('ru');
      await locale.close();
      final restart = LocaleCubit(const FlutterSecureStorage());
      await restart.restore();
      expect(restart.state.languageCode, 'ru');
      await restart.close();
    },
  );
  test('every ARB message is translated with matching placeholders', () {
    final ru =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync())
            as Map<String, dynamic>;
    final ky =
        jsonDecode(File('lib/l10n/app_ky.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = ru.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys, ky.keys.where((k) => !k.startsWith('@')).toSet());
    for (final key in keys) {
      expect((ky[key] as String).trim(), isNotEmpty, reason: key);
      final params = RegExp(r'\{arg\d+\}');
      expect(
        params.allMatches(ru[key] as String).map((m) => m[0]).toSet(),
        params.allMatches(ky[key] as String).map((m) => m[0]).toSet(),
        reason: key,
      );
    }
  });
  testWidgets('localized errors and placeholders preserve user data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ky'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(context.errorText('Неверный номер телефона или пароль')),
              Text(
                context.tr(
                  '«{arg0}» будет удалено без возможности восстановления.',
                  {'arg0': 'Ваше объявление'},
                ),
              ),
              const Text('Привет, Нурбек!'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Телефон номери же сырсөз туура эмес'), findsOneWidget);
    expect(
      find.text('«Ваше объявление» калыбына келтирилгис болуп өчүрүлөт.'),
      findsOneWidget,
    );
    expect(find.text('Привет, Нурбек!'), findsOneWidget);
  });
  test(
    'temporary refresh failure preserves tokens and is not reported as expired login',
    () async {
      const storage = TokenStorage(FlutterSecureStorage());
      final refresh = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) => h.reject(
              DioException(
                requestOptions: r,
                type: DioExceptionType.connectionError,
              ),
            ),
          ),
        );
      final dio = Dio()
        ..interceptors.add(
          AuthInterceptor(Dio(), storage, refreshClient: refresh),
        );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) => h.reject(
            DioException(
              requestOptions: r,
              response: Response(requestOptions: r, statusCode: 401),
            ),
            true,
          ),
        ),
      );
      try {
        await dio.get<dynamic>('http://fixture/profile');
        fail('request should fail');
      } on DioException catch (error) {
        expect(error.type, DioExceptionType.connectionError);
        expect(error.response?.statusCode, isNot(401));
      }
      expect(await storage.refreshToken, 'refresh');
      expect(await storage.accessToken, 'old');
    },
  );
  test('rejected refresh clears only session keys', () async {
    const storage = TokenStorage(FlutterSecureStorage());
    final refresh = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) => h.reject(
            DioException(
              requestOptions: r,
              response: Response(requestOptions: r, statusCode: 401),
            ),
            true,
          ),
        ),
      );
    final dio = Dio()
      ..interceptors.add(
        AuthInterceptor(Dio(), storage, refreshClient: refresh),
      );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.reject(
          DioException(
            requestOptions: r,
            response: Response(requestOptions: r, statusCode: 401),
          ),
          true,
        ),
      ),
    );
    await expectLater(
      dio.get<dynamic>('http://fixture/profile'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.accessToken, isNull);
    expect(await storage.refreshToken, isNull);
    expect(
      await const FlutterSecureStorage().read(key: 'preferred_locale'),
      'ky',
    );
  });
  test('logout during refresh cannot resurrect previous tokens', () async {
    const storage = TokenStorage(FlutterSecureStorage());
    final pending = Completer<void>();
    final refresh = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) async {
            await pending.future;
            h.resolve(
              Response(
                requestOptions: r,
                statusCode: 200,
                data: {
                  'data': {
                    'access_token': 'new',
                    'refresh_token': 'new-refresh',
                  },
                },
              ),
            );
          },
        ),
      );
    final dio = Dio()
      ..interceptors.add(
        AuthInterceptor(Dio(), storage, refreshClient: refresh),
      );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) => h.reject(
          DioException(
            requestOptions: r,
            response: Response(requestOptions: r, statusCode: 401),
          ),
          true,
        ),
      ),
    );
    final request = expectLater(
      dio.get<dynamic>('http://fixture/profile'),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await storage.clear();
    pending.complete();
    await request;
    expect(await storage.accessToken, isNull);
    expect(await storage.refreshToken, isNull);
  });
}
