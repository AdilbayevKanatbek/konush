import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/app/app.dart';
import 'package:konush/src/app/router.dart';
import 'package:konush/src/app/theme.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_flow_cubit.dart';
import 'package:konush/src/features/chat/presentation/chat_cubit.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/cubit/listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/my_listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:konush/src/features/complexes/presentation/construction_widgets.dart';
import 'package:konush/src/features/complexes/presentation/construction_filters.dart';
import 'package:konush/src/features/complexes/presentation/construction_contacts.dart';
import 'package:konush/src/features/complexes/presentation/construction_financing.dart';
import '../../ui/redesign_test.dart'
    show TestAuthRepository, TestListingsRepository;
import '../../support/chat_fakes.dart';

final _complex = <String, dynamic>{
  'id': 'c1',
  'name': 'ЖК Тестовый сад',
  'company_id': 'co1',
  'company_name': 'Тест Строй',
  'address': 'Бишкек, тестовый адрес',
  'description': 'Описание жилого комплекса.',
  'latitude': 42.875,
  'longitude': 74.6,
  'price_from': 4500000,
  'parking_price_from': 600000,
  'construction_stage': 'frame',
  'readiness_percent': 70,
  'handover_year': 2025,
  'handover_quarter': 2,
  'created_at': '2025-01-01T00:00:00Z',
  'catalog_updated_at': '2025-03-01T00:00:00Z',
  'progress_updated_at': '2026-09-01T00:00:00Z',
  'units_available': 3,
  'units_total': 5,
  'photos': <Json>[],
  'unit_summary': [
    {
      'unit_type': 'apartment',
      'rooms': 0,
      'available_count': 2,
      'total_count': 3,
      'min_area': 30,
      'max_area': 38,
      'min_price': 4500000,
    },
    {
      'unit_type': 'parking',
      'available_count': 1,
      'total_count': 2,
      'min_price': 600000,
    },
  ],
  'mortgage_programs': [_program],
  'installment_plans': [_plan],
};
final _unit = <String, dynamic>{
  'id': 'u1',
  'complex_id': 'c1',
  'unit_type': 'apartment',
  'rooms': 0,
  'number': '17',
  'building': 'А',
  'area': 32.5,
  'floor': 3,
  'price': 4500000,
  'price_per_m2': 138462,
  'sale_status': 'available',
  'finishing': 'none',
  'photos': <Json>[],
};
final _program = <String, dynamic>{
  'id': 'p1',
  'name': 'Тестовая ипотека',
  'bank': {'name': 'Тест Банк'},
  'rate_from': 12.0,
  'rate_to': 15.0,
  'max_term_years': 20,
  'min_down_pct': 20,
  'max_amount_som': 1000000,
  'conditions_verified_at': '2026-07-01',
  'is_active': true,
};
final _plan = <String, dynamic>{
  'id': 'i1',
  'title': 'Рассрочка для квартир',
  'term_months': 12,
  'payment_interval_months': 3,
  'down_payment_pct': 20,
  'markup_pct': 10,
  'unit_types': ['apartment'],
  'status': 'active',
  'is_active': true,
};
late TestAuthRepository auth;
late List<Json> complexItems;
late List<Json> unitItems;
final calls = <RequestOptions>[];
bool missingComplex = false, rateUnavailable = false;
bool Function(RequestOptions, RequestInterceptorHandler)? intercept;

void reply(
  RequestOptions options,
  RequestInterceptorHandler handler,
  Object? data, {
  Json? meta,
}) {
  handler.resolve(
    Response(
      requestOptions: options,
      statusCode: 200,
      data: {'success': true, 'data': data, 'meta': ?meta},
    ),
  );
}

void fail(
  RequestOptions options,
  RequestInterceptorHandler handler,
  int status, {
  String code = 'NOT_FOUND',
}) {
  handler.reject(
    DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: {
          'success': false,
          'error': {'code': code, 'message': 'test error'},
        },
      ),
    ),
  );
}

void dispatch(RequestOptions options, RequestInterceptorHandler handler) {
  calls.add(options);
  if (intercept?.call(options, handler) == true) return;
  final page = options.queryParameters['page'] ?? 1;
  switch (options.path) {
    case '/exchange-rates/latest':
      rateUnavailable
          ? fail(options, handler, 404, code: 'RATE_NOT_FOUND')
          : reply(options, handler, {'rate': 87.45});
    case '/residential-complexes':
      reply(
        options,
        handler,
        complexItems,
        meta: {
          'page': page,
          'per_page': 20,
          'total': complexItems.length,
          'total_pages': 1,
        },
      );
    case '/residential-complexes/c1':
      missingComplex
          ? fail(options, handler, 404)
          : reply(options, handler, _complex);
    case '/units':
      reply(
        options,
        handler,
        unitItems,
        meta: {
          'page': page,
          'per_page': 20,
          'total': unitItems.length,
          'total_pages': 1,
        },
      );
    case '/units/u1':
      reply(options, handler, unitItems.first);
    case '/companies/co1':
      reply(options, handler, {
        'id': 'co1',
        'name': 'Тест Строй',
        'owner_id': 'other-owner',
        'phone': '+996700123456',
        'description': 'О компании',
      });
    case '/mortgage/programs':
      reply(options, handler, [_program]);
    case '/leads/contact-events':
      reply(options, handler, {});
    case '/leads/callbacks':
      reply(options, handler, {'id': 'request1'});
    case '/leads/my':
      reply(
        options,
        handler,
        [
          {
            'id': 'request1',
            'target_type': 'unit',
            'unit_id': 'u1',
            'target_title': 'ЖК Тестовый сад · №17',
            'status': 'new',
          },
        ],
        meta: {'page': 1, 'per_page': 20, 'total': 1, 'total_pages': 1},
      );
    default:
      fail(options, handler, 404);
  }
}

final frame = GlobalKey();
const capture = bool.fromEnvironment('CAPTURE_CONSTRUCTION');
Future<void> snapshot(WidgetTester tester, String name) async {
  if (!capture) return;
  await tester.runAsync(() async {
    final boundary =
        frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('../output/construction-20260927/screenshots')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<GoRouter> mount(
  WidgetTester tester,
  String route, {
  bool small = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = small
      ? const Size(320, 700)
      : const Size(390, 844);
  tester.platformDispatcher.textScaleFactorTestValue = small ? 1.3 : 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = createAppRouter(initialLocation: route);
  await tester.pumpWidget(
    RepaintBoundary(
      key: frame,
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

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 35,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final chip = find.ancestor(
    of: finder,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is ActionChip || widget is ChoiceChip || widget is FilterChip,
    ),
  );
  await tester.tap(chip.evaluate().isEmpty ? finder : chip.first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    if (capture) {
      final bytes = File(
        '../output/konush-redesign/Onest.ttf',
      ).readAsBytesSync();
      await (FontLoader(
        'Onest',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  setUp(() async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    auth = TestAuthRepository();
    final listings = TestListingsRepository();
    sl.registerFactory(() => AuthCubit(auth));
    sl.registerFactory(() => AuthFlowCubit(auth));
    sl.registerFactory(
      () => FavoritesCubit(listings, auth, const FlutterSecureStorage()),
    );
    sl.registerFactory(
      () => ChatCubit(TestChatRepository(), TestChatRealtime()),
    );
    sl.registerFactory(() => ListingsCubit(listings));
    sl.registerFactory(() => MyListingsCubit(listings));
    sl.registerSingleton<ListingsRepository>(listings);
    sl.registerSingleton(
      ApiClient(
        Dio()..interceptors.add(InterceptorsWrapper(onRequest: dispatch)),
      ),
    );
    calls.clear();
    intercept = null;
    missingComplex = false;
    rateUnavailable = false;
    complexItems = [
      {..._complex},
    ];
    unitItems = [
      {..._unit},
    ];
  });
  tearDown(() async => sl.reset());

  test(
    'prices exclude parking except when apartment/office aggregate is absent',
    () {
      expect(ResidentialComplex.fromJson(_complex).displayPrice, 4500000);
      final parking = ResidentialComplex.fromJson({
        ..._complex,
        'price_from': null,
      });
      expect(parking.displayPrice, 600000);
      expect(parking.parkingOnly, isTrue);
      expect(ResidentialComplex.fromJson({'id': 'empty'}).displayPrice, isNull);
    },
  );
  test(
    'quarter deadline uses Bishkek midnight; completed and unknown are not overdue',
    () {
      final complex = ResidentialComplex.fromJson({
        ..._complex,
        'handover_year': 2026,
        'handover_quarter': 2,
      });
      expect(
        handoverOverdue(complex, DateTime.parse('2026-06-30T17:59:59Z')),
        isFalse,
      );
      expect(
        handoverOverdue(complex, DateTime.parse('2026-06-30T18:00:00Z')),
        isTrue,
      );
      expect(
        handoverOverdue(
          ResidentialComplex.fromJson({
            ..._complex,
            'construction_stage': 'completed',
          }),
          DateTime(2027),
        ),
        isFalse,
      );
      expect(
        handoverOverdue(
          ResidentialComplex.fromJson({'id': 'c'}),
          DateTime(2027),
        ),
        isFalse,
      );
    },
  );
  test(
    'price freshness falls back to publication and rejects invalid map coordinates',
    () {
      expect(
        staleCatalog(
          ResidentialComplex.fromJson({
            'id': 'c',
            'created_at': '2026-01-01T00:00:00Z',
          }),
          DateTime.utc(2026, 2, 2),
        ),
        isTrue,
      );
      expect(
        staleCatalog(
          ResidentialComplex.fromJson({'id': 'c'}),
          DateTime.utc(2026, 2, 2),
        ),
        isFalse,
      );
      expect(validPoint(0, 0), isFalse);
      expect(validPoint(double.nan, 74), isFalse);
      expect(validPoint(91, 74), isFalse);
      expect(phoneDisplay('+996700123456'), '+996 700 123 456');
    },
  );
  test(
    'mortgage matches reference formula including zero interest and full down payment',
    () {
      final result = mortgageCalculation(
        price: 1000000,
        downPct: 0,
        ratePct: 12,
        years: 1,
      );
      expect(result.monthly, 88849);
      expect(result.total, 1066188);
      expect(result.overpay, 66188);
      expect(
        mortgageCalculation(
          price: 1200000,
          downPct: 20,
          ratePct: 0,
          years: 1,
        ).monthly,
        80000,
      );
      expect(
        mortgageCalculation(
          price: 1200000,
          downPct: 100,
          ratePct: 12,
          years: 1,
        ).monthly,
        0,
      );
    },
  );
  test(
    'installment markup applies before down payment; type restrictions and invalid period',
    () {
      final plan = InstallmentPlan(_plan);
      final result = installmentCalculation(1000000, plan);
      expect(
        [result.total, result.down, result.payments, result.payment],
        [1100000, 220000, 4, 220000],
      );
      expect(plan.fits('parking'), isFalse);
      expect(
        InstallmentPlan({..._plan, 'unit_types': []}).fits('parking'),
        isTrue,
      );
      expect(
        () => installmentCalculation(
          100,
          InstallmentPlan({..._plan, 'payment_interval_months': 0}),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'repository uses server pagination, preserves filters, includes all sale statuses by default',
    () async {
      final repo = constructionRepository();
      final result = await repo.list(
        page: 2,
        perPage: 100,
        filters: {
          'class': 'comfort,business',
          'rooms': '0,2',
          'price_max': 1000000,
        },
      );
      expect(calls.last.queryParameters, containsPair('per_page', 50));
      expect(calls.last.queryParameters, containsPair('rooms', '0,2'));
      expect(result.meta.perPage, 20);
      expect(result.meta.page, 2);
      await repo.units('c1');
      expect(calls.last.queryParameters, containsPair('complex_id', 'c1'));
      expect(calls.last.queryParameters.containsKey('sale_status'), isFalse);
    },
  );
  test('currency gracefully falls back on missing or invalid rate', () async {
    rateUnavailable = true;
    expect(await constructionRepository().exchangeRate(), isNull);
    intercept = (o, h) {
      reply(o, h, {'rate': 0});
      return true;
    };
    expect(await constructionRepository().exchangeRate(), isNull);
  });

  testWidgets(
    'catalog renders parking fallback and preserves som when rate is missing',
    (tester) async {
      rateUnavailable = true;
      complexItems = [
        {..._complex, 'price_from': null},
      ];
      await mount(tester, '/complexes');
      expect(find.textContaining('Машиноместа от'), findsOneWidget);
      expect(find.textContaining('Срок сдачи прошёл'), findsOneWidget);
      expect(find.textContaining('Цена не указана'), findsNothing);
      expect(tester.takeException(), isNull);
      await snapshot(tester, 'catalog-parking');
    },
  );
  testWidgets(
    'empty catalog and filtered empty state differ; map remains visible',
    (tester) async {
      complexItems = [];
      await mount(tester, '/complexes', small: true);
      expect(find.text('Жилых комплексов пока нет'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Нет такого ЖК');
      await tap(tester, find.byTooltip('Найти'));
      expect(find.text('Ничего не найдено по этим фильтрам'), findsOneWidget);
      await tap(tester, find.text('Карта'));
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Ничего не найдено по этим фильтрам'), findsOneWidget);
      expect(
        calls
            .lastWhere((o) => o.path == '/residential-complexes')
            .queryParameters['per_page'],
        50,
      );
      expect(tester.takeException(), isNull);
      await snapshot(tester, 'map-empty-small');
    },
  );
  testWidgets(
    'complex map marker opens correct detail and back returns to map',
    (tester) async {
      final router = await mount(tester, '/complexes');
      await tap(tester, find.text('Карта'));
      expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('tile.openstreetmap.org'),
      );
      await tap(tester, find.byKey(const ValueKey('complex-pin-c1')));
      expect(router.state.uri.path, '/complexes/c1');
      await tap(tester, find.byTooltip('Назад').first);
      expect(find.byKey(const ValueKey('complex-pin-c1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'filter invalid range stays in form; correction submits city and exact studio',
    (tester) async {
      await mount(tester, '/complexes');
      await tap(tester, find.text('Фильтры'));
      await tester.enterText(
        find.byKey(const ValueKey('filter-handover_year_min')),
        '2028',
      );
      await tester.enterText(
        find.byKey(const ValueKey('filter-handover_year_max')),
        '2027',
      );
      await tap(tester, find.text('Применить'));
      expect(
        find.text('Максимум должен быть не меньше минимума'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('filter-handover_year_max')),
        '2030',
      );
      await tap(tester, find.text('Применить'));
      expect(find.byType(ConstructionFilters), findsNothing);
      final query = calls
          .lastWhere((o) => o.path == '/residential-complexes')
          .queryParameters;
      expect(query['handover_year_min'], 2028);
      expect(query['handover_year_max'], 2030);
      expect(query.containsKey('room_choice'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'hidden parent makes unit unavailable and offers catalog return',
    (tester) async {
      missingComplex = true;
      final router = await mount(tester, '/complexes/c1/units/u1');
      expect(find.text('Объект недоступен'), findsOneWidget);
      expect(find.text('Студия'), findsNothing);
      await tap(tester, find.text('Вернуться в каталог'));
      expect(router.state.uri.path, '/complexes');
    },
  );
  testWidgets(
    'same unit route reloads changed identity rather than reusing old object',
    (tester) async {
      final router = await mount(tester, '/units/u1');
      expect(find.text('Студия'), findsOneWidget);
      router.go('/units/missing');
      await tester.pumpAndSettle();
      expect(find.text('Объект недоступен'), findsOneWidget);
      expect(find.text('Студия'), findsNothing);
    },
  );
  testWidgets('sold units stay visible and navigate to available filter', (
    tester,
  ) async {
    unitItems = [
      {..._unit, 'sale_status': 'sold'},
    ];
    final router = await mount(tester, '/units/u1');
    expect(find.text('Продано'), findsOneWidget);
    await tap(tester, find.text('Посмотреть свободные'));
    expect(router.state.uri.path, '/complexes/c1/units');
    expect(
      calls.lastWhere((o) => o.path == '/units').queryParameters['sale_status'],
      'available',
    );
  });
  testWidgets(
    'contact phone telemetry is once per reveal and callback body has no profile fields',
    (tester) async {
      await mount(tester, '/companies/co1');
      await tap(tester, find.text('Связаться с застройщиком'));
      final phone = find.widgetWithText(OutlinedButton, 'Показать телефон');
      await tester.tap(phone);
      await tester.tap(phone);
      await tester.pumpAndSettle();
      expect(find.text('+996 700 123 456'), findsOneWidget);
      expect(
        calls.where((o) => o.path == '/leads/contact-events'),
        hasLength(1),
      );
      await tap(tester, find.text('Заказать звонок'));
      await tap(tester, find.text('Отправить заявку'));
      expect(find.text('Заявка отправлена'), findsOneWidget);
      final sent = calls.singleWhere((o) => o.path == '/leads/callbacks');
      expect(sent.data, {
        'target_type': 'company',
        'target_id': 'co1',
        'preferred_time': 'any',
        'comment': '',
      });
      await snapshot(tester, 'callback-success');
    },
  );
  testWidgets(
    'guest login returns to retained contact target and callback form',
    (tester) async {
      auth.signedIn = false;
      final router = await mount(tester, '/companies/co1');
      await tap(tester, find.text('Связаться с застройщиком'));
      await tap(tester, find.text('Заказать звонок'));
      expect(router.state.uri.path, '/login');
      final authContext = tester.element(find.byType(TextFormField).first);
      // Actual form submission verifies that the route and modal survive login.
      await tester.enterText(find.byType(TextFormField).first, '700123456');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tap(tester, find.widgetWithText(FilledButton, 'Войти'));
      expect(authContext.mounted, isFalse);
      expect(find.byType(CallbackForm), findsOneWidget);
      await tap(tester, find.text('Отправить заявку'));
      expect(
        (calls.singleWhere((o) => o.path == '/leads/callbacks').data
            as Map)['target_id'],
        'co1',
      );
    },
  );
  testWidgets(
    'unknown callback outcome blocks duplicate submission and exposes request list',
    (tester) async {
      intercept = (o, h) {
        if (o.path != '/leads/callbacks') return false;
        fail(o, h, 502, code: 'INTERNAL');
        return true;
      };
      await mount(tester, '/companies/co1');
      await tap(tester, find.text('Связаться с застройщиком'));
      await tap(tester, find.text('Заказать звонок'));
      await tap(tester, find.text('Отправить заявку'));
      expect(find.textContaining('Ответ не получен'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Отправить заявку'),
            )
            .onPressed,
        isNull,
      );
      expect(calls.where((o) => o.path == '/leads/callbacks'), hasLength(1));
      await tap(tester, find.text('Мои заявки'));
      expect(find.text('ЖК Тестовый сад · №17'), findsOneWidget);
    },
  );
  testWidgets(
    'mortgage calculator warns about program limit and clears stale result on edit',
    (tester) async {
      await mount(tester, '/mortgage', small: true);
      await tap(tester, find.text('Тестовая ипотека'));
      final calculator = find.byType(MortgageCalculator);
      await tester.scrollUntilVisible(
        calculator,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find
            .descendant(of: calculator, matching: find.byType(TextFormField))
            .first,
        '4500000',
      );
      await tap(tester, find.text('Рассчитать ипотеку'));
      expect(
        find.text('Сумма кредита превышает лимит программы'),
        findsOneWidget,
      );
      expect(find.textContaining('В месяц:'), findsOneWidget);
      await snapshot(tester, 'mortgage-calculator-small');
      await tester.enterText(
        find
            .descendant(of: calculator, matching: find.byType(TextFormField))
            .first,
        '100000',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('В месяц:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'selected room filter can be cleared without clearing other filters',
    (tester) async {
      await mount(tester, '/complexes/c1/units?unit_type=apartment&rooms=0');
      await tap(tester, find.text('Фильтры'));
      final room = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.key.toString().contains('room_choice'),
      );
      await tap(tester, room);
      await tap(tester, find.text('Все').last);
      await tap(tester, find.text('Применить'));
      final params = calls.lastWhere((o) => o.path == '/units').queryParameters;
      expect(params.containsKey('rooms'), isFalse);
      expect(params['unit_type'], 'apartment');
    },
  );
  testWidgets('pagination uses next meta page and removes overlap on map', (
    tester,
  ) async {
    intercept = (o, h) {
      if (o.path != '/residential-complexes') return false;
      final page = o.queryParameters['page'] as int;
      reply(
        o,
        h,
        page == 1
            ? [_complex]
            : [
                _complex,
                {
                  ..._complex,
                  'id': 'c2',
                  'name': 'ЖК Второй',
                  'latitude': 40.5,
                  'longitude': 72.8,
                },
              ],
        meta: {'page': page, 'per_page': 1, 'total': 2, 'total_pages': 2},
      );
      return true;
    };
    await mount(tester, '/complexes');
    await tap(tester, find.text('Карта'));
    await tap(tester, find.text('Загрузить ещё'));
    expect(
      calls
          .lastWhere((o) => o.path == '/residential-complexes')
          .queryParameters['page'],
      2,
    );
    expect(find.byKey(const ValueKey('complex-pin-c1')), findsOneWidget);
    expect(find.byKey(const ValueKey('complex-pin-c2')), findsOneWidget);
    expect(find.text('Загрузить ещё'), findsNothing);
  });
  testWidgets('late old search response cannot replace newer results', (
    tester,
  ) async {
    RequestOptions? old;
    RequestInterceptorHandler? held;
    intercept = (o, h) {
      if (o.path == '/residential-complexes' &&
          o.queryParameters['q'] == 'old') {
        old = o;
        held = h;
        return true;
      }
      return false;
    };
    await mount(tester, '/complexes');
    await tester.enterText(find.byType(TextField).first, 'old');
    await tester.tap(find.byTooltip('Найти'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(held, isNotNull);
    complexItems = [
      {..._complex, 'name': 'Свежий результат'},
    ];
    await tester.enterText(find.byType(TextField).first, 'new');
    await tester.tap(find.byTooltip('Найти'));
    await tester.pumpAndSettle();
    reply(
      old!,
      held!,
      [
        {..._complex, 'name': 'Устаревший результат'},
      ],
      meta: {'page': 1, 'per_page': 20, 'total': 1, 'total_pages': 1},
    );
    await tester.pumpAndSettle();
    expect(find.text('Свежий результат'), findsOneWidget);
    expect(find.text('Устаревший результат'), findsNothing);
  });
  testWidgets(
    'callback submission guards double tap while request is pending',
    (tester) async {
      RequestOptions? pending;
      RequestInterceptorHandler? held;
      intercept = (o, h) {
        if (o.path != '/leads/callbacks') return false;
        pending = o;
        held = h;
        return true;
      };
      await mount(tester, '/companies/co1');
      await tap(tester, find.text('Связаться с застройщиком'));
      await tap(tester, find.text('Заказать звонок'));
      final button = find.widgetWithText(FilledButton, 'Отправить заявку');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls.where((o) => o.path == '/leads/callbacks'), hasLength(1));
      reply(pending!, held!, {'id': 'new'});
      await tester.pumpAndSettle();
      expect(find.text('Заявка отправлена'), findsOneWidget);
    },
  );
  for (final error in {
    'PHONE_NOT_VERIFIED': (403, 'Подтвердите телефон перед отправкой заявки'),
    'CALLBACK_EXISTS': (
      409,
      'Заявка на этот объект уже отправлена. Проверьте мои заявки.',
    ),
    'OWN_TARGET': (422, 'Нельзя отправить заявку на свой объект'),
  }.entries) {
    testWidgets('callback translates ${error.key} without claiming success', (
      tester,
    ) async {
      intercept = (o, h) {
        if (o.path != '/leads/callbacks') return false;
        fail(o, h, error.value.$1, code: error.key);
        return true;
      };
      await mount(tester, '/companies/co1');
      await tap(tester, find.text('Связаться с застройщиком'));
      await tap(tester, find.text('Заказать звонок'));
      await tap(tester, find.text('Отправить заявку'));
      expect(find.text(error.value.$2), findsOneWidget);
      expect(find.text('Заявка отправлена'), findsNothing);
    });
  }
  testWidgets('parking unit never offers apartment installment plan', (
    tester,
  ) async {
    unitItems = [
      {..._unit, 'unit_type': 'parking', 'rooms': null},
    ];
    await mount(tester, '/units/u1');
    await tester.scrollUntilVisible(
      find.text('Связаться с застройщиком'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Рассрочка для квартир'), findsNothing);
    expect(find.text('Тестовая ипотека'), findsOneWidget);
  });
  testWidgets('Kyrgyz catalog and filters fit small phone', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'preferred_locale': 'ky'});
    complexItems = [];
    await mount(tester, '/complexes', small: true);
    expect(find.text('Жилых комплексов пока нет'), findsNothing);
    final filter = find.byWidgetPredicate(
      (w) =>
          w is ActionChip &&
          w.avatar is Icon &&
          (w.avatar as Icon).icon == Icons.tune,
    );
    await tap(tester, filter);
    expect(
      find.descendant(
        of: find.byType(ConstructionFilters),
        matching: find.text('Чыпкалар'),
      ),
      findsOneWidget,
    );
    expect(find.text('Колдонуу'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await snapshot(tester, 'filters-ky-small');
  });
  testWidgets('map network failure does not claim that the catalog is empty', (
    tester,
  ) async {
    intercept = (o, h) {
      if (o.path != '/residential-complexes') return false;
      fail(o, h, 503, code: 'INTERNAL');
      return true;
    };
    await mount(tester, '/complexes');
    await tap(tester, find.text('Карта'));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Жилых комплексов пока нет'), findsNothing);
    expect(find.text('Повторить'), findsOneWidget);
  });
  testWidgets(
    'system back closes filters and contacts; both reopen without navigating away',
    (tester) async {
      final router = await mount(tester, '/complexes');
      await tap(tester, find.text('Фильтры'));
      expect(find.text('Применить').hitTestable(), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ConstructionFilters), findsNothing);
      await tap(tester, find.text('Фильтры'));
      await tap(tester, find.byTooltip('Закрыть'));
      router.go('/companies/co1');
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tap(tester, find.text('Связаться с застройщиком'));
        await tap(tester, find.text('Показать телефон'));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ContactSheet), findsNothing);
        expect(router.state.uri.path, '/companies/co1');
      }
      expect(
        calls.where((o) => o.path == '/leads/contact-events'),
        hasLength(2),
      );
    },
  );
  for (final entry in {
    'complex': '/complexes/c1',
    'unit': '/units/u1',
    'units': '/complexes/c1/units',
    'company': '/companies/co1',
    'mortgage': '/mortgage',
    'requests': '/my-requests',
  }.entries) {
    testWidgets('populated ${entry.key} fits small phone with large text', (
      tester,
    ) async {
      await mount(tester, entry.value, small: true);
      expect(tester.takeException(), isNull);
      await snapshot(tester, '${entry.key}-small');
    });
  }
}
