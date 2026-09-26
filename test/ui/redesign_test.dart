import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../support/chat_fakes.dart';
import 'package:konush/src/features/chat/presentation/chat_cubit.dart';
import 'package:konush/src/app/app.dart';
import 'dart:io';
import 'dart:async';
import 'package:konush/src/core/storage/token_storage.dart';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/app/router.dart';
import 'package:konush/src/app/theme.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/network/pagination.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/domain/auth_repository.dart';
import 'package:konush/src/features/auth/domain/user.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_flow_cubit.dart';
import 'package:konush/src/features/listings/data/listing_model.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/my_listings_cubit.dart';

const _capture = bool.fromEnvironment('CAPTURE_UI');
const _fontPath = String.fromEnvironment('UI_FONT');
const _output = String.fromEnvironment(
  'UI_OUTPUT',
  defaultValue: '../output/konush-redesign',
);
final _frame = GlobalKey();
final _user = User(
  id: 'fixture-user',
  phone: '+996700123456',
  name: 'Айбек',
  role: UserRole.user,
  isVerified: true,
  isBanned: false,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
final _fixtures = <Listing>[
  ListingModel.fromJson({
    'id': 'fixture-sale',
    'title': 'Светлая квартира у парка',
    'description':
        'Просторная квартира с отдельной кухней. Тихий двор, рядом школа и парк.',
    'price': 9600000,
    'price_usd': 110000,
    'rooms': 3,
    'area': 86,
    'floor': 5,
    'floors': 10,
    'year': 2022,
    'address': 'Бишкек, улица Токтогула, 125',
    'agent_name': 'Айбек',
    'contact_phone': _user.phone,
    'created_at': '2026-09-14T10:00:00Z',
    'views_count': 127,
    'latitude': 42.87,
    'longitude': 74.6,
  }),
  ListingModel.fromJson({
    'id': 'fixture-rent',
    'title': 'Квартира в центре',
    'deal_type': 'rent',
    'price': 45000,
    'rooms': 2,
    'area': 58,
    'floor': 3,
    'floors': 9,
    'address': 'Бишкек, бульвар Эркиндик, 42',
    'created_at': '2026-09-13T10:00:00Z',
  }),
];

class TestAuthRepository extends Fake implements AuthRepository {
  bool signedIn = true;
  bool failOtp = false;
  String? loginPhone;
  RegisterParams? registration;
  ResetPasswordParams? passwordReset;
  int otpSends = 0;
  int resetSends = 0;
  final verifiedCodes = <String>[];
  @override
  Future<bool> hasSession() async => signedIn;
  @override
  Future<User> getProfile() async => _user;
  @override
  Future<User> login({required String phone, required String password}) async {
    loginPhone = phone;
    signedIn = true;
    return _user;
  }

  @override
  Future<User> register(RegisterParams params) async {
    registration = params;
    signedIn = true;
    return _user;
  }

  @override
  Future<void> sendOtp(String phone) async {
    otpSends++;
    if (failOtp) throw const AppException('Попробуйте позже');
  }

  @override
  Future<void> verifyOtp({required String phone, required String code}) async {
    verifiedCodes.add(code);
  }

  @override
  Future<DevOtpCode> getDevOtp(String phone) async =>
      throw UnsupportedError('disabled in tests');
  @override
  Future<void> requestPasswordReset(String phone) async {
    resetSends++;
  }

  @override
  Future<String> verifyResetCode({
    required String phone,
    required String code,
  }) async => 'fixture-reset-token';
  @override
  Future<void> resetPassword(ResetPasswordParams params) async {
    passwordReset = params;
  }

  @override
  Future<void> logout() async {
    signedIn = false;
  }
}

const _ownedEditJson = <String, dynamic>{
  'id': 'owned-edit',
  'user_id': 'fixture-user',
  'status': 'pending',
  'title': 'Квартира для проверки переходов',
  'description': 'Просторная квартира с отдельной кухней рядом с тихим парком.',
  'price': 5000000,
  'area': 60,
  'rooms': 2,
  'city_id': '00000000-0000-0000-0000-000000000001',
  'address': 'Улица Тестовая, 12',
  'latitude': 42.87,
  'longitude': 74.6,
};

class TestListingsRepository extends Fake implements ListingsRepository {
  List<Listing> items = [..._fixtures];
  bool fail = false;
  bool failFavorite = false;
  List<Listing>? favoriteItems;
  Future<PaginatedResult<Listing>> Function(ListingFilter)? loader;
  final details = <String, Listing>{};
  final detailRequests = <String>[];
  final filters = <ListingFilter>[];
  final removed = <String>[];
  final added = <String>[];
  final deleted = <String>[];
  Object? deletionError;
  Completer<void>? deletionGate;
  final contacts = <String>[];
  PaginatedResult<Listing> result(List<Listing> values) => PaginatedResult(
    items: values,
    meta: PaginationMeta(
      page: 1,
      perPage: 20,
      total: values.length,
      totalPages: values.isEmpty ? 0 : 1,
    ),
  );
  @override
  Future<PaginatedResult<Listing>> getListings(ListingFilter filter) async {
    filters.add(filter);
    if (loader != null) return loader!(filter);
    if (fail) throw const AppException('Нет соединения');
    return result(
      items
          .where(
            (i) => filter.dealType == null || i.dealType == filter.dealType,
          )
          .toList(),
    );
  }

  @override
  Future<Listing> getById(String id) async {
    detailRequests.add(id);
    if (fail) throw const AppException('Нет соединения');
    return details[id] ?? items.firstWhere((i) => i.id == id);
  }

  @override
  Future<Listing> getMyById(String id) => getById(id);

  @override
  Future<PaginatedResult<Listing>> getFavorites({
    int page = 1,
    int perPage = 50,
  }) async => result(favoriteItems ?? items);
  @override
  Future<void> addFavorite(String id) async {
    added.add(id);
    if (failFavorite) throw const AppException('offline');
  }

  @override
  Future<void> removeFavorite(String id) async {
    removed.add(id);
  }

  @override
  Future<PaginatedResult<Listing>> getMyListings({
    int page = 1,
    int perPage = 20,
  }) async => result(items);
  @override
  Future<void> deleteListing(String id) async {
    deleted.add(id);
    if (deletionGate != null) await deletionGate!.future;
    if (deletionError != null) throw deletionError!;
  }

  @override
  Future<void> recordContact(String id, {String type = 'phone_view'}) async {
    contacts.add(id);
  }
}

late TestAuthRepository auth;
late TestListingsRepository listings;
late TestChatRepository chatRepository;

Future<GoRouter> _mount(
  WidgetTester tester,
  String route, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = createAppRouter(initialLocation: route);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _frame,
      child: KonushApp(
        router: router,
        theme: AppTheme.build(
          textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Onest'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
  return router;
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!_capture) return;
  await tester.runAsync(() async {
    final boundary =
        _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_output)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    if (_fontPath.isNotEmpty) {
      final bytes = File(_fontPath).readAsBytesSync();
      await (FontLoader(
        'Onest',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  setUp(() async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    auth = TestAuthRepository();
    listings = TestListingsRepository();
    chatRepository = TestChatRepository();
    sl.registerFactory(() => AuthCubit(auth));
    sl.registerFactory(
      () => FavoritesCubit(listings, auth, const FlutterSecureStorage()),
    );
    sl.registerFactory(() => ChatCubit(chatRepository, TestChatRealtime()));
    sl.registerFactory(() => AuthFlowCubit(auth));
    sl.registerFactory(() => ListingsCubit(listings));
    sl.registerFactory(() => MyListingsCubit(listings));
    sl.registerSingleton<ListingsRepository>(listings);
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) =>
              handler.reject(DioException(requestOptions: options)),
        ),
      );
    sl.registerSingleton(ApiClient(dio));
  });
  tearDown(() async {
    await sl.reset();
  });

  const routes = <String, String>{
    'home': '/',
    'catalog': '/listings',
    'favorites': '/favorites',
    'account': '/profile',
    'settings': '/settings',
    'messages': '/messages',
    'support': '/support',
    'submit': '/submit',
    'login': '/login',
    'register': '/register',
    'otp': '/verify-phone?phone=%2B996700123456',
    'forgot': '/forgot-password',
    'password': '/new-password?phone=%2B996700123456&token=fixture-token',
    'my-listings': '/my-listings',
    'detail': '/listings/fixture-sale',
    'complexes': '/complexes',
    'complex-detail': '/complexes/alatoo',
  };
  for (final viewport in ['phone', 'small-large-text', 'wide']) {
    for (final route in routes.entries) {
      testWidgets('${route.key} fits $viewport', (tester) async {
        await _mount(
          tester,
          route.value,
          size: viewport == 'wide'
              ? const Size(1200, 900)
              : viewport == 'phone'
              ? const Size(390, 844)
              : const Size(320, 700),
          scale: viewport == 'small-large-text' ? 1.3 : 1,
        );
        expect(tester.takeException(), isNull);
        if (viewport == 'phone') await _snapshot(tester, route.key);
        if (viewport == 'small-large-text' && route.key == 'home') {
          await _snapshot(tester, 'home-small-large-text');
        }
      });
    }
  }

  testWidgets('five tabs navigate; submit closes back to previous tab', (
    tester,
  ) async {
    final router = await _mount(tester, '/');
    for (final entry in {
      'Избранное': '/favorites',
      'Сообщения': '/messages',
      'Кабинет': '/profile',
    }.entries) {
      await _tap(tester, find.text(entry.key).last);
      expect(router.routeInformationProvider.value.uri.path, entry.value);
    }
    await _tap(tester, find.text('Подать'));
    expect(find.text('Подать объявление'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Далее'))
          .onPressed,
      isNotNull,
    );
    await _tap(tester, find.byTooltip('Закрыть'));
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    await _tap(tester, find.text('Главная'));
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('favorite action calls existing repository and saves locally', (
    tester,
  ) async {
    listings.favoriteItems = [];
    await _mount(tester, '/listings');
    await _tap(tester, find.byTooltip('Добавить в избранное').first);
    expect(listings.added, ['fixture-sale']);
    expect(
      await const FlutterSecureStorage().read(
        key: 'favorite_listing_ids_fixture-user',
      ),
      contains('fixture-sale'),
    );
    await _tap(tester, find.byTooltip('Убрать из избранного').first);
    expect(listings.removed, ['fixture-sale']);
  });

  testWidgets('removing favorite hides its card', (tester) async {
    await _mount(tester, '/favorites');
    await _tap(tester, find.byTooltip('Убрать из избранного').first);
    expect(listings.removed, ['fixture-sale']);
    expect(find.text('Бишкек, улица Токтогула, 125'), findsNothing);
    expect(find.text('1 сохранено'), findsOneWidget);
  });

  testWidgets('login keeps +996 normalization and authenticates', (
    tester,
  ) async {
    auth.signedIn = false;
    final router = await _mount(tester, '/login');
    await tester.enterText(find.byType(TextFormField).at(0), '+996700123456');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await _tap(tester, find.widgetWithText(FilledButton, 'Войти'));
    expect(auth.loginPhone, '+996700123456');
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets(
    'registration passes real fields and opens six-digit verification',
    (tester) async {
      auth.signedIn = false;
      final router = await _mount(tester, '/register');
      await tester.enterText(find.byType(TextFormField).at(0), 'Айбек');
      await tester.enterText(find.byType(TextFormField).at(1), '+996700123456');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await _tap(tester, find.widgetWithText(FilledButton, 'Создать аккаунт'));
      expect(auth.registration?.phone, '+996700123456');
      expect(auth.registration?.name, 'Айбек');
      expect(router.state.uri.path, '/verify-phone');
      expect(auth.otpSends, 1);
    },
  );

  testWidgets('OTP with keyboard rejects four digits and accepts six', (
    tester,
  ) async {
    final router = await _mount(
      tester,
      '/verify-phone?phone=%2B996700123456',
      size: const Size(320, 700),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await _tap(tester, find.widgetWithText(FilledButton, 'Подтвердить'));
    expect(auth.verifiedCodes, isEmpty);
    expect(find.text('Введите шестизначный код'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Подтвердить'),
    );
    await tester.pumpAndSettle();
    await _snapshot(tester, 'otp-keyboard');
    await _tap(tester, find.widgetWithText(FilledButton, 'Подтвердить'));
    expect(auth.verifiedCodes, ['123456']);
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed OTP sends once and retries only on user action', (
    tester,
  ) async {
    auth.failOtp = true;
    await _mount(tester, '/verify-phone?phone=%2B996700123456');
    await tester.pump(const Duration(seconds: 10));
    expect(auth.otpSends, 1);
    await _tap(tester, find.text('Отправить код повторно'));
    expect(auth.otpSends, 2);
  });

  testWidgets(
    'password recovery carries phone and reset token to existing operation',
    (tester) async {
      final router = await _mount(tester, '/forgot-password');
      await tester.enterText(find.byType(TextFormField), '+996700123456');
      await _tap(tester, find.text('Получить код'));
      expect(auth.resetSends, 1);
      await tester.enterText(find.byType(TextField), '123456');
      await _tap(tester, find.widgetWithText(FilledButton, 'Подтвердить'));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'newpassword123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newpassword123',
      );
      await _tap(tester, find.byType(FilledButton));
      expect(auth.passwordReset?.phone, '+996700123456');
      expect(auth.passwordReset?.resetToken, 'fixture-reset-token');
      expect(router.routeInformationProvider.value.uri.path, '/login');
    },
  );

  testWidgets(
    'deletion requires confirmation and removes only selected listing',
    (tester) async {
      await _mount(tester, '/my-listings');
      await _tap(tester, find.byTooltip('Удалить объявление').first);
      await _tap(tester, find.text('Отмена'));
      expect(listings.deleted, isEmpty);
      await _tap(tester, find.byTooltip('Удалить объявление').first);
      await _tap(tester, find.text('Удалить'));
      expect(listings.deleted, ['fixture-sale']);
      expect(find.text('Светлая квартира у парка'), findsNothing);
      expect(find.text('Квартира в центре'), findsOneWidget);
    },
  );

  testWidgets(
    'failed deletion stays visible at the bottom and can be retried',
    (tester) async {
      listings.items = List.generate(
        8,
        (index) => ListingModel.fromJson({
          'id': 'owned-$index',
          'title': 'Объект $index',
          'status': 'pending',
        }),
      );
      listings.deletionError = const AppException(
        'Ошибка удаления',
        statusCode: 500,
      );
      await _mount(tester, '/my-listings');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('delete-owned-7')),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await _tap(tester, find.byKey(const ValueKey('delete-owned-7')));
      await _tap(tester, find.text('Удалить'));
      expect(listings.deleted, ['owned-7']);
      expect(find.text('Объект 7'), findsOneWidget);
      final snackbar = find.byType(SnackBar);
      expect(snackbar, findsOneWidget);
      expect(
        find.descendant(
          of: snackbar,
          matching: find.textContaining('Не удалось удалить объявление'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(snackbar).overlaps(const Rect.fromLTWH(0, 0, 390, 844)),
        isTrue,
      );
      expect(find.text('Объявление удалено'), findsNothing);
      await _snapshot(tester, 'deletion-failure');

      listings.deletionError = null;
      await _tap(tester, find.text('Повторить'));
      await _tap(tester, find.text('Удалить'));
      expect(listings.deleted, ['owned-7', 'owned-7']);
      expect(find.text('Объект 7'), findsNothing);
      expect(find.text('Объявление удалено'), findsOneWidget);
      final cubit = tester
          .element(find.text('Объект 6'))
          .read<MyListingsCubit>();
      expect((cubit.state as MyListingsLoaded).total, 7);
    },
  );

  testWidgets('all delete buttons are disabled while deletion is pending', (
    tester,
  ) async {
    listings.deletionGate = Completer<void>();
    await _mount(tester, '/my-listings');
    await _tap(tester, find.byTooltip('Удалить объявление').first);
    await tester.tap(find.text('Удалить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(listings.deleted, ['fixture-sale']);
    final buttons = tester.widgetList<IconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == 'Удалить объявление',
      ),
    );
    expect(buttons.length, 2);
    expect(buttons.every((button) => button.onPressed == null), isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    listings.deletionGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Светлая квартира у парка'), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('delete-fixture-rent')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('contact sheet shows provided phone and records view only once', (
    tester,
  ) async {
    await _mount(tester, '/listings/fixture-sale');
    await _tap(tester, find.text('Связаться с продавцом'));
    expect(listings.contacts, ['fixture-sale']);
    expect(find.text('+996 700 123 456'), findsOneWidget);
    await _tap(tester, find.byIcon(Icons.close));
    await _tap(tester, find.text('Связаться с продавцом'));
    expect(listings.contacts, ['fixture-sale']);
  });

  for (final saveFails in [false, true]) {
    testWidgets(
      'my listings reopen after editing ${saveFails ? 'fails' : 'succeeds'}',
      (tester) async {
        var data = {..._ownedEditJson};
        listings.items = [ListingModel.fromJson(data)];
        await sl.unregister<ApiClient>();
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                expect(options.method, 'PUT');
                expect(options.path, '/listings/owned-edit');
                if (saveFails) {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      type: DioExceptionType.badResponse,
                      response: Response(
                        requestOptions: options,
                        statusCode: 502,
                      ),
                    ),
                  );
                } else {
                  data = {...data, ...options.data as Map<String, dynamic>};
                  listings.items = [ListingModel.fromJson(data)];
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {'success': true, 'data': data},
                    ),
                  );
                }
              },
            ),
          );
        sl.registerSingleton(ApiClient(dio));
        final router = await _mount(tester, '/profile');
        await _tap(tester, find.text('Открыть мои объявления'));
        await _tap(tester, find.text('Редактировать'));
        await tester.enterText(
          find.byKey(const ValueKey('Заголовок')),
          'Обновлённая квартира рядом с парком',
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.text('Сохранить изменения'));
        if (saveFails) {
          await tester.pump(const Duration(seconds: 7));
          await _tap(tester, find.text('Проверить мои объявления'));
        } else {
          expect(find.text('Изменения сохранены'), findsOneWidget);
          await _tap(tester, find.text('Открыть объявление'));
          await _tap(tester, find.byTooltip('Назад'));
        }
        expect(router.state.uri.path, '/my-listings');
        await _tap(tester, find.byTooltip('Назад'));
        expect(router.state.uri.path, '/profile');
        await _tap(tester, find.text('Открыть мои объявления'));
        expect(router.state.uri.path, '/my-listings');
        expect(find.text(data['title'] as String), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final origin in ['/my-listings', '/my-listings/owned-edit']) {
    for (final systemBack in [false, true]) {
      testWidgets(
        'edited form returns to $origin with ${systemBack ? 'system back' : 'close'} and reopens',
        (tester) async {
          listings.items = [ListingModel.fromJson(_ownedEditJson)];
          final router = await _mount(tester, origin);
          await _tap(tester, find.text('Редактировать'));
          await tester.enterText(
            find.byKey(const ValueKey('Заголовок')),
            'Несохранённое изменение квартиры',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          if (systemBack) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          } else {
            await _tap(tester, find.byTooltip('Закрыть'));
          }
          expect(
            find.text('Несохранённые изменения будут потеряны.'),
            findsOneWidget,
          );
          await _tap(tester, find.text('Отмена'));
          expect(find.text('Несохранённое изменение квартиры'), findsOneWidget);
          await _tap(tester, find.byTooltip('Закрыть'));
          await _tap(tester, find.widgetWithText(FilledButton, 'Закрыть'));
          expect(router.state.uri.path, origin);
          await _tap(tester, find.text('Редактировать'));
          expect(router.state.uri.path, '/my-listings/owned-edit/edit');
          expect(find.text(_ownedEditJson['title'] as String), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final state in ['editable', 'unavailable', 'failed']) {
    testWidgets('direct edit $state returns to my listings with system back', (
      tester,
    ) async {
      listings.items = [
        ListingModel.fromJson({
          ..._ownedEditJson,
          if (state == 'unavailable') 'status': 'archived',
        }),
      ];
      listings.fail = state == 'failed';
      final router = await _mount(tester, '/my-listings/owned-edit/edit');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/my-listings');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'edit loading failure can be retried and the form can be closed',
    (tester) async {
      listings.items = [ListingModel.fromJson(_ownedEditJson)];
      listings.fail = true;
      final router = await _mount(tester, '/my-listings/owned-edit/edit');
      expect(find.text('Не удалось загрузить объявление'), findsOneWidget);
      listings.fail = false;
      await _tap(tester, find.text('Повторить'));
      expect(find.text('Расскажите об объекте'), findsOneWidget);
      await _tap(tester, find.byTooltip('Закрыть'));
      expect(router.state.uri.path, '/my-listings');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog map shows a listing outside Bishkek and opens its card',
    (tester) async {
      listings.items = [
        ListingModel.fromJson({
          ..._ownedEditJson,
          'latitude': 40.5283,
          'longitude': 72.7985,
        }),
      ];
      final router = await _mount(tester, '/listings');
      await _tap(tester, find.text('Карта'));
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(Uri.parse(tileLayer.urlTemplate!).host, 'tile.openstreetmap.org');
      expect(tileLayer.urlTemplate, isNot(contains('access_token')));
      final marker = find.byKey(const ValueKey('map-listing-owned-edit'));
      expect(marker.hitTestable(), findsOneWidget);
      await tester.tap(marker);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/listings/owned-edit');
      await _tap(tester, find.byTooltip('Назад'));
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog map remains visible for empty search at large text size',
    (tester) async {
      listings.items = [];
      await _mount(tester, '/listings', size: const Size(320, 700), scale: 1.3);
      await _tap(tester, find.text('Карта'));
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        isEmpty,
      );
      expect(find.text('Объявлений: 0'), findsOneWidget);
      await _tap(tester, find.text('Список'));
      expect(find.text('Пока ничего не нашли'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog map fits distant listings and skips missing coordinates',
    (tester) async {
      listings.items = [
        ListingModel.fromJson({..._ownedEditJson, 'id': 'bishkek'}),
        ListingModel.fromJson({
          ..._ownedEditJson,
          'id': 'osh',
          'latitude': 40.5283,
          'longitude': 72.7985,
        }),
        ListingModel.fromJson({
          ..._ownedEditJson,
          'id': 'no-location',
          'latitude': 0,
          'longitude': 0,
        }),
      ];
      await _mount(tester, '/listings');
      await _tap(tester, find.text('Карта'));
      expect(
        find.byKey(const ValueKey('map-listing-bishkek')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('map-listing-osh')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('map-listing-no-location')),
        findsNothing,
      );
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('catalog error is recoverable and rent tab keeps deal filter', (
    tester,
  ) async {
    listings.fail = true;
    await _mount(tester, '/listings?tab=rent');
    expect(find.text('Не удалось загрузить'), findsOneWidget);
    listings.fail = false;
    await _tap(tester, find.text('Повторить'));
    expect(listings.filters.last.dealType, DealType.rent);
    expect(find.text('Не удалось загрузить'), findsNothing);
  });

  testWidgets('empty favorites and guest account have usable entry actions', (
    tester,
  ) async {
    auth.signedIn = false;
    await _mount(tester, '/favorites');
    expect(find.text('Сохраните то, что нравится'), findsOneWidget);
    await _tap(tester, find.text('Кабинет'));
    await _snapshot(tester, 'account-guest');
    await _tap(tester, find.text('Войти или зарегистрироваться'));
    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
  });

  for (final entry in {...routes, 'conversation': '/messages/chat-1'}.entries) {
    testWidgets('Kyrgyz ${entry.key} fits narrow large text', (tester) async {
      await const FlutterSecureStorage().write(
        key: 'preferred_locale',
        value: 'ky',
      );
      chatRepository.inbox = [fixtureConversation];
      chatRepository.history = [
        fixtureMessage('hello'),
        fixtureMessage(
          'reply',
          sender: 'fixture-user',
          content: 'Добрый день',
          read: true,
        ),
      ];
      await _mount(tester, entry.value, size: const Size(320, 700), scale: 1.3);
      expect(
        Localizations.localeOf(
          tester.element(find.byType(Scaffold).last),
        ).languageCode,
        'ky',
      );
      expect(tester.takeException(), isNull);
      if ([
        'home',
        'conversation',
        'settings',
        'login',
        'support',
      ].contains(entry.key)) {
        await _snapshot(tester, 'ky-${entry.key}');
      }
    });
  }
  testWidgets('language switches from home, settings and survives logout', (
    tester,
  ) async {
    final router = await _mount(tester, '/');
    await _tap(tester, find.text('РУС'));
    await _snapshot(tester, 'language-picker');
    await _tap(tester, find.text('Кыргызча'));
    expect(find.text('Башкы бет'), findsOneWidget);
    expect(
      await const FlutterSecureStorage().read(key: 'preferred_locale'),
      'ky',
    );
    await _tap(tester, find.text('Кабинет'));
    await _tap(tester, find.byTooltip('Жөндөөлөр'));
    await _tap(tester, find.text('Чыгуу'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Чыгуу'));
    expect(router.state.uri.path, '/');
    expect(find.text('Башкы бет'), findsOneWidget);
    expect(
      await const FlutterSecureStorage().read(key: 'preferred_locale'),
      'ky',
    );
    await _tap(tester, find.text('КЫР'));
    await _tap(tester, find.text('Русский'));
    expect(find.text('Главная'), findsOneWidget);
  });
  testWidgets(
    'system Back dismisses keyboard, sheet, nested page then confirms exit once',
    (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final router = await _mount(tester, '/');
      await _tap(tester, find.text('Купить'));
      await _tap(tester, find.byTooltip('Фильтры'));
      await tester.tap(find.byType(TextFormField).first);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Показать объявления'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .focusNode
            .hasFocus,
        isFalse,
      );
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Показать объявления'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await _snapshot(tester, 'exit-confirmation');
      expect(find.text('Выйти из приложения?'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Выйти'));
      expect(calls.where((m) => m == 'SystemNavigator.pop').length, 1);
    },
  );
  for (final route in [
    '/login',
    '/register',
    '/verify-phone?phone=%2B996700123456',
    '/forgot-password',
    '/new-password?phone=x&token=x',
    '/listings',
    '/messages/chat-1',
  ]) {
    testWidgets('blank tap closes keyboard on $route', (tester) async {
      if (route == '/login' || route == '/register') auth.signedIn = false;
      await _mount(tester, route);
      final field = find.byType(EditableText).first;
      await tester.tap(field);
      await tester.pump();
      expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
      await tester.tapAt(const Offset(2, 150));
      await tester.pump();
      expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'moving between fields keeps focus and password visibility does not submit',
    (tester) async {
      auth.signedIn = false;
      await _mount(tester, '/register');
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pump();
      await tester.tap(find.byType(TextFormField).at(1));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await _tap(tester, find.byTooltip('Показать пароль'));
      expect(auth.registration, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('search passes text to API and tab return preserves it', (
    tester,
  ) async {
    await _mount(tester, '/listings');
    await tester.enterText(find.byType(TextField).first, '  Парк  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(listings.filters.last.query, 'Парк');
    await _tap(tester, find.text('Избранное').last);
    await _tap(tester, find.text('Главная').last);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '  Парк  ',
    );
  });
  testWidgets(
    'chat starts from listing, sends once and preserves draft on return',
    (tester) async {
      chatRepository.inbox = [fixtureConversation];
      final router = await _mount(tester, '/listings/fixture-sale');
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Написать'));
      expect(router.state.uri.path, '/messages/chat-1');
      expect(chatRepository.starts, ['fixture-sale']);
      await tester.enterText(find.byType(TextField), 'Здравствуйте');
      await _tap(tester, find.byTooltip('Отправить'));
      expect(chatRepository.sends, ['Здравствуйте']);
      expect(find.text('Здравствуйте'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Черновик вопроса');
      await _tap(tester, find.byTooltip('Назад'));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Написать'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Черновик вопроса',
      );
      await _snapshot(tester, 'chat');
    },
  );

  testWidgets(
    'chat remains usable with keyboard and network errors in Kyrgyz',
    (tester) async {
      await const FlutterSecureStorage().write(
        key: 'preferred_locale',
        value: 'ky',
      );
      chatRepository.failSend = true;
      await _mount(
        tester,
        '/messages/chat-1',
        size: const Size(320, 700),
        scale: 1.3,
      );
      await tester.enterText(find.byType(TextField), 'Вопрос');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Жөнөтүү'));
      chatRepository.fail = true;
      await _tap(tester, find.byTooltip('Жаңыртуу'));
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Вопрос',
      );
      await _snapshot(tester, 'ky-chat-keyboard-error');
    },
  );
  testWidgets('iOS keeps interactive edge back gesture', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final router = await _mount(tester, '/');
    await _tap(tester, find.text('Купить'));
    await tester.dragFrom(const Offset(1, 220), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/');
    expect(find.text('Выйти из приложения?'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets(
    'filter invalid range is blocked, decimal comma works, reset is transactional',
    (tester) async {
      await _mount(tester, '/listings');
      await _tap(tester, find.byTooltip('Фильтры'));
      await tester.enterText(find.byType(TextFormField).at(0), '100');
      await tester.enterText(find.byType(TextFormField).at(1), '50');
      await _tap(tester, find.text('Показать объявления'));
      expect(find.text('Не меньше значения «От»'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), '150');
      await tester.enterText(find.byType(TextFormField).at(2), '42,5');
      await _tap(tester, find.text('Показать объявления'));
      expect(listings.filters.last.priceMin, 100);
      expect(listings.filters.last.areaMin, 42.5);
      await _tap(tester, find.byTooltip('Фильтры'));
      await _tap(tester, find.text('Сбросить фильтры'));
      await _tap(tester, find.text('Показать объявления'));
      expect(listings.filters.last.priceMin, isNull);
      expect(listings.filters.last.areaMin, isNull);
    },
  );
  test(
    'catalog pagination keeps filters, ignores duplicate load and retries errors',
    () async {
      final cubit = ListingsCubit(listings);
      addTearDown(cubit.close);
      var fail = true;
      final next = Completer<PaginatedResult<Listing>>();
      listings.loader = (filter) async {
        if (filter.page == 1) {
          return PaginatedResult(
            items: [_fixtures.first],
            meta: const PaginationMeta(
              page: 1,
              perPage: 1,
              total: 2,
              totalPages: 2,
            ),
          );
        }
        if (fail) throw const AppException('offline');
        return next.future;
      };
      await cubit.load(
        const ListingFilter(query: 'Парк', rooms: 3, perPage: 1),
      );
      await cubit.loadMore();
      expect((cubit.state as ListingsLoaded).items, [_fixtures.first]);
      expect((cubit.state as ListingsLoaded).moreError, isNotNull);
      fail = false;
      final load = cubit.loadMore();
      await cubit.loadMore();
      next.complete(
        PaginatedResult(
          items: [_fixtures.last],
          meta: const PaginationMeta(
            page: 2,
            perPage: 1,
            total: 2,
            totalPages: 2,
          ),
        ),
      );
      await load;
      expect((cubit.state as ListingsLoaded).items.length, 2);
      expect(listings.filters.last.query, 'Парк');
      expect(listings.filters.last.rooms, 3);
      expect(listings.filters.length, 3);
    },
  );
  test(
    'favorites isolate account caches and rollback network failure',
    () async {
      final favorites = FavoritesCubit(
        listings,
        auth,
        const FlutterSecureStorage(),
      );
      addTearDown(favorites.close);
      await const FlutterSecureStorage().write(
        key: 'favorite_listing_ids_fixture-user',
        value: '["first"]',
      );
      await const FlutterSecureStorage().write(
        key: 'favorite_listing_ids_other',
        value: '["second"]',
      );
      await favorites.setUser('fixture-user');
      expect(favorites.state.ids, {'first'});
      await favorites.setUser('other');
      expect(favorites.state.ids, {'second'});
      listings.failFavorite = true;
      await favorites.toggle('third');
      expect(favorites.state.ids, {'second'});
      expect(favorites.state.pending, isEmpty);
      expect(favorites.state.message, isNotNull);
      await favorites.setUser(null);
      expect(favorites.state.ids, isEmpty);
      expect(
        await const FlutterSecureStorage().read(
          key: 'favorite_listing_ids_fixture-user',
        ),
        '["first"]',
      );
    },
  );

  group('usability regression', () {
    testWidgets('system back asks before exiting and cancellation keeps root', (
      tester,
    ) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _mount(tester, '/');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Выйти из приложения?'), findsOneWidget);
      expect(calls, isNot(contains('SystemNavigator.pop')));
      await _tap(tester, find.text('Отмена'));
      expect(find.text('Дом начинается здесь'), findsOneWidget);
    });
    testWidgets('cancelled filter draft does not change later requests', (
      tester,
    ) async {
      await _mount(tester, '/listings');
      await _tap(tester, find.byTooltip('Фильтры'));
      await _tap(tester, find.widgetWithText(ChoiceChip, '3'));
      await _tap(tester, find.byTooltip('Закрыть'));
      await _tap(tester, find.text('Арендовать'));
      expect(listings.filters.last.rooms, isNull);
    });
    testWidgets('opening listing from a summary fetches full contact details', (
      tester,
    ) async {
      final full = _fixtures.first;
      listings.details[full.id] = full;
      listings.items = [
        ListingModel.fromJson({
          'id': full.id,
          'title': full.title,
          'price_usd': 110000,
        }),
      ];
      await _mount(tester, '/listings');
      await _tap(tester, find.text(r'$110 000'));
      await _tap(tester, find.text('Связаться с продавцом'));
      expect(listings.detailRequests, contains(full.id));
      expect(find.text('+996 700 123 456'), findsOneWidget);
    });
    test('guest favorites survive temporary detail request failure', () async {
      auth.signedIn = false;
      listings.fail = true;
      FlutterSecureStorage.setMockInitialValues({
        'favorite_listing_ids': '["fixture-sale"]',
      });
      final cubit = FavoritesCubit(
        listings,
        auth,
        const FlutterSecureStorage(),
      );
      await cubit.restore();
      await cubit.load();
      expect(cubit.state.ids, contains('fixture-sale'));
      expect(cubit.state.message, isNotNull);
      await cubit.close();
    });
    test('clearing session keeps unrelated app preferences', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'fixture-access',
        'refresh_token': 'fixture-refresh',
        'preferred_locale': 'ky',
        'favorite_listing_ids': '["fixture-sale"]',
      });
      const storage = FlutterSecureStorage();
      await const TokenStorage(storage).clear();
      expect(await storage.read(key: 'preferred_locale'), 'ky');
      expect(await storage.read(key: 'favorite_listing_ids'), isNotNull);
      expect(await storage.read(key: 'access_token'), isNull);
    });
    test('slow catalog response cannot replace a newer selection', () async {
      final first = Completer<PaginatedResult<Listing>>();
      final second = Completer<PaginatedResult<Listing>>();
      listings.loader = (filter) =>
          filter.dealType == DealType.sale ? first.future : second.future;
      final cubit = ListingsCubit(listings);
      final one = cubit.load(const ListingFilter(dealType: DealType.sale));
      final two = cubit.load(const ListingFilter(dealType: DealType.rent));
      second.complete(listings.result([_fixtures.last]));
      await two;
      first.complete(listings.result([_fixtures.first]));
      await one;
      expect((cubit.state as ListingsLoaded).items.single.id, 'fixture-rent');
      await cubit.close();
    });
  });
}
