import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:konush/l10n/generated/app_localizations.dart';
import 'package:konush/src/app/theme.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/network/auth_interceptor.dart';
import 'package:konush/src/core/storage/token_storage.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/complexes/data/complex_repository.dart';
import 'package:konush/src/features/complexes/presentation/complexes_page.dart';
import 'package:konush/src/features/listings/data/listing_model.dart';
import 'package:konush/src/features/listings/data/listing_submission.dart';
import 'package:konush/src/features/listings/data/listings_remote_data_source.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/submit_listing_page.dart';
import 'package:konush/src/features/listings/presentation/pages/edit_listing_page.dart';
import 'package:konush/src/features/listings/presentation/pages/my_listings_page.dart';
import 'package:konush/src/features/listings/presentation/pages/listing_detail_page.dart';
import 'package:konush/src/features/listings/presentation/cubit/my_listings_cubit.dart';
import 'package:konush/src/core/network/pagination.dart';
import '../../ui/redesign_test.dart' show TestAuthRepository;

const _capture = bool.fromEnvironment('CAPTURE_STAGE_UI');
final _frame = GlobalKey();
Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!_capture) return;
  await tester.runAsync(() async {
    final boundary =
        _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('../output/api-review-20260926/screenshots')
      ..createSync(recursive: true);
    File(
      '${folder.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jA9kAAAAASUVORK5CYII=',
);
Listing _listing([Map<String, dynamic> extra = const {}]) =>
    ListingModel.fromJson({
      'id': 'created-listing',
      'title': 'Тестовая квартира',
      'status': 'pending',
      ...extra,
    });

class SubmissionFake extends ListingSubmissionRepository {
  SubmissionFake() : super(ApiClient(Dio()));
  int creates = 0;
  int updates = 0;
  String? updatedId;
  final deletions = <String>[];
  String? failedDeletion;
  final uploads = <String>[];
  Map<String, dynamic>? draft;
  Object? createError;
  String? failedPhoto;
  Completer<void>? creationGate;
  @override
  Future<Listing> create(Map<String, dynamic> data) async {
    creates++;
    draft = data;
    if (creationGate != null) await creationGate!.future;
    if (createError != null) throw createError!;
    return _listing();
  }

  @override
  Future<Listing> update(String id, Map<String, dynamic> data) async {
    updates++;
    updatedId = id;
    draft = data;
    if (creationGate != null) await creationGate!.future;
    if (createError != null) throw createError!;
    return _listing({'id': id, ...data});
  }

  @override
  Future<void> deletePhoto(String id, String photoId) async {
    expect(id, 'created-listing');
    if (photoId == failedDeletion) {
      throw const AppException('Ошибка фото', code: 'TEST', statusCode: 400);
    }
    deletions.add(photoId);
  }

  @override
  Future<void> upload(String id, ListingUpload photo) async {
    expect(id, 'created-listing');
    if (photo.name == failedPhoto) {
      throw const AppException(
        'Ошибка фото',
        code: 'UPLOAD_ERROR',
        statusCode: 400,
      );
    }
    uploads.add(photo.name);
  }
}

Listing _editable([Map<String, dynamic> extra = const {}]) => _listing({
  'user_id': 'fixture-user',
  'title': 'Квартира у тихого парка',
  'description': 'Просторная квартира с хорошим ремонтом и большой кухней.',
  'address': 'Улица Тестовая, 12',
  'city_id': '00000000-0000-0000-0000-000000000001',
  'price': 5500000,
  'area': 65,
  'rooms': 2,
  'floor': 3,
  'floors': 9,
  'latitude': 42.87,
  'longitude': 74.6,
  'district_id': 'preserved-district',
  'year': 2020,
  'land_area': 4.5,
  'price_usd': 65000,
  'contact_phone': '+996700123456',
  ...extra,
});

class OwnedListings extends Fake implements ListingsRepository {
  int loads = 0;
  Listing item = _editable();
  @override
  Future<Listing> getMyById(String id) async {
    loads++;
    expect(id, item.id);
    return item;
  }

  @override
  Future<PaginatedResult<Listing>> getMyListings({
    int page = 1,
    int perPage = 20,
  }) async => PaginatedResult(
    items: [item],
    meta: PaginationMeta.fromJson({
      'page': 1,
      'per_page': perPage,
      'total': 1,
      'total_pages': 1,
    }),
  );
}

class MissingListings extends Fake implements ListingsRepository {
  @override
  Future<Listing> getById(String id) async => throw const AppException(
    'Не найдено',
    statusCode: 404,
    code: 'NOT_FOUND',
  );
}

ApiClient _api(
  void Function(RequestOptions, RequestInterceptorHandler) handler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://fixture/api/v1'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: handler));
  return ApiClient(dio);
}

void _reply(
  RequestOptions options,
  RequestInterceptorHandler handler,
  Object? data, {
  Map<String, dynamic>? meta,
}) {
  handler.resolve(
    Response(
      requestOptions: options,
      statusCode: 200,
      data: {'success': true, 'data': data, 'meta': ?meta},
    ),
  );
}

Future<void> _mount(
  WidgetTester tester,
  Widget page, {
  Locale locale = const Locale('ru'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => AuthCubit(TestAuthRepository())..restoreSession(),
      child: MaterialApp(
        theme: AppTheme.build(
          textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Onest'),
        ),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepaintBoundary(key: _frame, child: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scroll(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 30,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _fillSubmission(
  WidgetTester tester, {
  Map<String, String> overrides = const {},
}) async {
  for (final entry in {
    'Заголовок': 'Квартира у тихого парка',
    'Описание': 'Просторная квартира с хорошим ремонтом и большой кухней.',
    'Цена, сом': '5500000',
    'Площадь, м²': '65',
    'Адрес': 'Улица Тестовая, 12',
    ...overrides,
  }.entries) {
    final field = find.byKey(ValueKey(entry.key));
    await _scroll(tester, field);
    await tester.enterText(field, entry.value);
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    if (_capture) {
      final bytes = File(
        '../output/konush-redesign/Onest.ttf',
      ).readAsBytesSync();
      await (FontLoader(
        'Onest',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() async {
    await sl.reset();
  });
  test('favorite visibility is optional and false is preserved', () {
    expect(_listing().isPublic, isNull);
    expect(_listing({'is_public': false}).isPublic, isFalse);
    expect(_listing({'is_public': true}).isPublic, isTrue);
    expect(_listing({'status': 'removed'}).status, ListingStatus.archived);
  });
  test('owner detail uses the authenticated owner endpoint', () async {
    final paths = <String>[];
    final source = ListingsRemoteDataSource(
      _api((o, h) {
        paths.add(o.path);
        _reply(o, h, {'id': 'own', 'status': 'pending'});
      }),
    );
    final item = await source.getMyById('own');
    expect(item.status, ListingStatus.pending);
    expect(paths, ['/listings/my/own']);
  });
  test('guest 404 keeps saved ID and marks it unavailable', () async {
    FlutterSecureStorage.setMockInitialValues({
      'favorite_listing_ids': '["saved"]',
    });
    final auth = TestAuthRepository()..signedIn = false;
    final cubit = FavoritesCubit(
      MissingListings(),
      auth,
      const FlutterSecureStorage(),
    );
    await cubit.restore();
    await cubit.load();
    expect(cubit.state.ids, {'saved'});
    expect(cubit.state.unavailableIds, {'saved'});
    expect(
      await const FlutterSecureStorage().read(key: 'favorite_listing_ids'),
      '["saved"]',
    );
    await cubit.close();
  });
  test(
    'complex catalog decodes current fields, nullable prices and pages',
    () async {
      final repo = ComplexRepository(
        _api((o, h) {
          expect(o.path, '/residential-complexes');
          expect(o.queryParameters, containsPair('q', 'Тест'));
          expect(o.queryParameters, containsPair('handover_completed', true));
          _reply(
            o,
            h,
            [
              {
                'id': 'complex',
                'name': 'Тест',
                'company_name': 'Застройщик',
                'price_from': null,
                'construction_stage': 'completed',
                'photos': [
                  {'url': 'https://fixture/photo.webp'},
                ],
              },
            ],
            meta: {'page': 2, 'per_page': 20, 'total': 21, 'total_pages': 2},
          );
        }),
      );
      final result = await repo.list(page: 2, query: 'Тест', completed: true);
      expect(result.meta.page, 2);
      expect(result.items.single.completed, isTrue);
      expect(result.items.single.priceFrom, isNull);
      expect(result.items.single.photos, hasLength(1));
    },
  );
  test(
    'submission retries remaining photos without creating another listing',
    () async {
      final repo = SubmissionFake()..failedPhoto = 'second.png';
      final controller = ListingSubmission(repo);
      final photos = [
        ListingUpload(name: 'first.png', bytes: _png),
        ListingUpload(name: 'second.png', bytes: _png),
      ];
      await controller.submit({'title': 'Тест'}, photos);
      expect(controller.complete, isFalse);
      expect(repo.creates, 1);
      expect(photos.first.uploaded, isTrue);
      repo.failedPhoto = null;
      await controller.submit({'title': 'Тест'}, photos);
      expect(repo.creates, 1);
      expect(repo.uploads, ['first.png', 'second.png']);
      expect(controller.complete, isTrue);
      await controller.submit({}, photos);
      expect(repo.creates, 1);
      controller.dispose();
    },
  );
  test('uncertain creation result blocks blind resubmission', () async {
    final repo = SubmissionFake()
      ..createError = const AppException('Не удалось связаться с сервером');
    final controller = ListingSubmission(repo);
    await controller.submit({}, []);
    await controller.submit({}, []);
    expect(repo.creates, 1);
    expect(controller.uncertain, isTrue);
    controller.dispose();
  });
  test(
    'double submission while creation is pending sends one request',
    () async {
      final gate = Completer<void>();
      final repo = SubmissionFake()..creationGate = gate;
      final controller = ListingSubmission(repo);
      final one = controller.submit({}, []);
      await controller.submit({}, []);
      expect(repo.creates, 1);
      gate.complete();
      await one;
      expect(controller.complete, isTrue);
      controller.dispose();
    },
  );
  test(
    'photo validation checks content and enforces size before HTTP',
    () async {
      int calls = 0;
      final repo = ListingSubmissionRepository(
        _api((o, h) {
          calls++;
          _reply(o, h, {});
        }),
      );
      await expectLater(
        repo.upload(
          'id',
          ListingUpload(name: 'fake.jpg', bytes: Uint8List.fromList([1, 2, 3])),
        ),
        throwsA(isA<AppException>()),
      );
      final big = Uint8List(10 * 1024 * 1024 + 1)
        ..setRange(0, _png.length, _png);
      await expectLater(
        repo.upload('id', ListingUpload(name: 'big.png', bytes: big)),
        throwsA(isA<AppException>()),
      );
      expect(calls, 0);
    },
  );
  test(
    'photo upload retries a fresh multipart body after token refresh',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'old',
        'refresh_token': 'old-refresh',
      });
      final refresh = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) => _reply(o, h, {
              'access_token': 'new',
              'refresh_token': 'new-refresh',
              'expires_in': 900,
            }),
          ),
        );
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture'));
      dio.interceptors.add(
        AuthInterceptor(
          dio,
          const TokenStorage(FlutterSecureStorage()),
          refreshClient: refresh,
        ),
      );
      int attempts = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) async {
            attempts++;
            final form = o.data as FormData;
            expect(form.isFinalized, isFalse);
            await form.finalize().drain<void>();
            if (attempts == 1) {
              h.reject(
                DioException(
                  requestOptions: o,
                  response: Response(requestOptions: o, statusCode: 401),
                ),
                true,
              );
            } else {
              expect(o.headers['Authorization'], 'Bearer new');
              _reply(o, h, {});
            }
          },
        ),
      );
      await ListingSubmissionRepository(
        ApiClient(dio),
      ).upload('id', ListingUpload(name: 'photo.png', bytes: _png));
      expect(attempts, 2);
    },
  );
  testWidgets('empty complexes do not show bundled demo properties', (
    tester,
  ) async {
    sl.registerSingleton(
      _api(
        (o, h) => _reply(
          o,
          h,
          [],
          meta: {'page': 1, 'per_page': 20, 'total': 0, 'total_pages': 0},
        ),
      ),
    );
    await _mount(tester, const ComplexesPage());
    expect(find.text('Жилых комплексов пока нет'), findsOneWidget);
    expect(find.text('Ала-Тоо Резиденс'), findsNothing);
    expect(tester.takeException(), isNull);
    await _snapshot(tester, 'complexes-empty');
  });
  testWidgets(
    'submission sends selected location and reaches moderation state',
    (tester) async {
      final repo = SubmissionFake();
      await _mount(
        tester,
        SubmitListingPage(
          repository: repo,
          pickLocation: () async => const LatLng(42.87, 74.6),
          pickPhotos: () async => [],
        ),
      );
      await _snapshot(tester, 'submission-type');
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
      await _snapshot(tester, 'submission-fields');
      await _fillSubmission(tester);
      final location = find.text('Указать место на карте');
      await _scroll(tester, location);
      await tester.tap(location);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отправить на проверку'));
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(repo.draft!['latitude'], 42.87);
      expect(repo.draft!['price'], 5500000);
      expect(find.text('Объявление отправлено на проверку'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _snapshot(tester, 'submission-success');
    },
  );
  testWidgets('missing fields never create a listing even when scrolled away', (
    tester,
  ) async {
    final repo = SubmissionFake();
    await _mount(
      tester,
      SubmitListingPage(
        repository: repo,
        pickLocation: () async => const LatLng(42.87, 74.6),
        pickPhotos: () async => [],
      ),
    );
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    final location = find.text('Указать место на карте');
    await _scroll(tester, location);
    await tester.tap(location);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отправить на проверку'));
    await tester.pumpAndSettle();
    expect(repo.creates, 0);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Заголовок: От 10 до 200 символов'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('Заголовок')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _snapshot(tester, 'submission-validation-error');
  });
  testWidgets(
    'selected map point does not hide a missing address; correction submits once',
    (tester) async {
      final repo = SubmissionFake();
      await _mount(
        tester,
        SubmitListingPage(
          repository: repo,
          pickPhotos: () async => [],
          pickLocation: () async => const LatLng(42.87, 74.6),
        ),
      );
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
      await _fillSubmission(tester, overrides: {'Адрес': ''});
      await _scroll(tester, find.text('Указать место на карте'));
      await tester.tap(find.text('Указать место на карте'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отправить на проверку'));
      await tester.pumpAndSettle();
      expect(repo.creates, 0);
      expect(find.text('Адрес: От 3 до 300 символов'), findsOneWidget);
      final address = find.byKey(const ValueKey('Адрес'));
      expect(address.hitTestable(), findsOneWidget);
      await tester.enterText(address, 'Улица Тестовая, 12');
      await tester.tap(find.text('Отправить на проверку'));
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(find.text('Объявление отправлено на проверку'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('short offscreen description names the field and scrolls to it', (
    tester,
  ) async {
    final repo = SubmissionFake();
    await _mount(
      tester,
      SubmitListingPage(
        repository: repo,
        pickPhotos: () async => [],
        pickLocation: () async => const LatLng(42.87, 74.6),
      ),
    );
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await _fillSubmission(tester, overrides: {'Описание': 'Квартира'});
    await _scroll(tester, find.text('Указать место на карте'));
    await tester.tap(find.text('Указать место на карте'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отправить на проверку'));
    await tester.pumpAndSettle();
    expect(repo.creates, 0);
    expect(find.text('Описание: От 20 до 5000 символов'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('Описание')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('submit without a map point explains the missing location', (
    tester,
  ) async {
    final repo = SubmissionFake();
    await _mount(
      tester,
      SubmitListingPage(repository: repo, pickPhotos: () async => []),
    );
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await _fillSubmission(tester);
    await _scroll(tester, find.byKey(const ValueKey('Заголовок')));
    await tester.tap(find.text('Отправить на проверку'));
    await tester.pumpAndSettle();
    expect(repo.creates, 0);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Выберите точное расположение объекта для отправки.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Указать место на карте').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'server rejection is visible even when the form is scrolled to the top',
    (tester) async {
      final repo = SubmissionFake()
        ..createError = const AppException(
          'Не удалось выполнить запрос',
          code: 'VALIDATION_ERROR',
          statusCode: 400,
        );
      await _mount(
        tester,
        SubmitListingPage(
          repository: repo,
          pickPhotos: () async => [],
          pickLocation: () async => const LatLng(42.87, 74.6),
        ),
      );
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
      await _fillSubmission(tester);
      await _scroll(tester, find.text('Указать место на карте'));
      await tester.tap(find.text('Указать место на карте'));
      await tester.pumpAndSettle();
      await _scroll(tester, find.byKey(const ValueKey('Заголовок')));
      await tester.tap(find.text('Отправить на проверку'));
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Не удалось выполнить запрос'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'editing uses PUT on the existing ID and deletes the selected photo',
    () async {
      final requests = <RequestOptions>[];
      final repo = ListingSubmissionRepository(
        _api((o, h) {
          requests.add(o);
          _reply(
            o,
            h,
            o.method == 'PUT'
                ? {
                    'id': 'existing',
                    'status': 'pending',
                    ...o.data as Map<String, dynamic>,
                  }
                : {},
          );
        }),
      );
      final result = await repo.update('existing', {
        'title': 'Новое название объявления',
        'price': 100,
      });
      await repo.deletePhoto('existing', 'old-photo');
      expect(result.id, 'existing');
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'PUT /listings/existing',
        'DELETE /listings/existing/photos/old-photo',
      ]);
    },
  );
  test(
    'editing retry skips the saved data, deleted photos and uploaded photos',
    () async {
      final repo = SubmissionFake()..failedPhoto = 'two.png';
      final submission = ListingSubmission(repo, listingId: 'created-listing');
      final photos = [
        ListingUpload(name: 'one.png', bytes: _png),
        ListingUpload(name: 'two.png', bytes: _png),
      ];
      await submission.submit(
        {'title': 'Изменённое объявление'},
        photos,
        removedPhotoIds: ['old'],
      );
      expect(submission.complete, isFalse);
      repo.failedPhoto = null;
      await submission.submit(
        {'title': 'Изменённое объявление'},
        photos,
        removedPhotoIds: ['old'],
      );
      expect(repo.creates, 0);
      expect(repo.updates, 1);
      expect(repo.deletions, ['old']);
      expect(repo.uploads, ['one.png', 'two.png']);
      expect(submission.complete, isTrue);
      submission.dispose();
    },
  );
  test(
    'editing retry after failed photo deletion preserves completed deletions',
    () async {
      final repo = SubmissionFake()..failedDeletion = 'second';
      final submission = ListingSubmission(repo, listingId: 'created-listing');
      await submission.submit({}, [], removedPhotoIds: ['first', 'second']);
      expect(submission.complete, isFalse);
      repo.failedDeletion = null;
      await submission.submit({}, [], removedPhotoIds: ['first', 'second']);
      expect(repo.updates, 1);
      expect(repo.deletions, ['first', 'second']);
      expect(submission.complete, isTrue);
      submission.dispose();
    },
  );
  test('double save sends one PUT and never creates another listing', () async {
    final repo = SubmissionFake()..creationGate = Completer<void>();
    final submission = ListingSubmission(repo, listingId: 'created-listing');
    final first = submission.submit({}, []);
    await submission.submit({}, []);
    expect(repo.updates, 1);
    expect(repo.creates, 0);
    repo.creationGate!.complete();
    await first;
    submission.dispose();
  });
  testWidgets(
    'edit pre-fills fields, preserves hidden attributes and clears an optional number',
    (tester) async {
      final repo = SubmissionFake();
      final item = _editable();
      await _mount(
        tester,
        SubmitListingPage(
          initialListing: item,
          repository: repo,
          pickPhotos: () async => [],
        ),
      );
      expect(find.text('Редактировать объявление'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('Заголовок')))
            .controller!
            .text,
        item.title,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Сохранить изменения'),
            )
            .onPressed,
        isNull,
      );
      await _snapshot(tester, 'edit-prefilled');
      await _scroll(tester, find.byKey(const ValueKey('Цена, сом')));
      await tester.enterText(
        find.byKey(const ValueKey('Цена, сом')),
        '5600000',
      );
      await _scroll(tester, find.byKey(const ValueKey('Комнат')));
      await tester.enterText(find.byKey(const ValueKey('Комнат')), '');
      await tester.tap(find.text('Сохранить изменения'));
      await tester.pumpAndSettle();
      expect(repo.creates, 0);
      expect(repo.updates, 1);
      expect(repo.updatedId, item.id);
      expect(repo.draft!['price'], 5600000);
      expect(repo.draft!['rooms'], isNull);
      expect(repo.draft!['title'], item.title);
      expect(repo.draft!['latitude'], item.latitude);
      expect(repo.draft!['district_id'], item.districtId);
      expect(repo.draft!['land_area'], item.landArea);
      expect(repo.draft!['year'], item.year);
      expect(repo.draft!['price_usd'], item.priceUsd);
      expect(repo.draft!['contact_phone'], item.contactPhone);
      expect(find.text('Изменения сохранены'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _snapshot(tester, 'edit-success');
    },
  );
  testWidgets(
    'removing an existing photo is staged and can be undone before save',
    (tester) async {
      final repo = SubmissionFake();
      final item = _editable({
        'photos': [
          {
            'id': 'old-photo',
            'listing_id': 'created-listing',
            'url': 'https://fixture/old.png',
            'order': 1,
          },
        ],
      });
      await _mount(
        tester,
        SubmitListingPage(
          initialListing: item,
          repository: repo,
          pickPhotos: () async => [],
        ),
      );
      final remove = find.byKey(const ValueKey('existing-photo-old-photo'));
      await _scroll(tester, remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(repo.deletions, isEmpty);
      expect(find.byTooltip('Вернуть фото'), findsOneWidget);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Вернуть фото'), findsNothing);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить изменения'));
      await tester.pumpAndSettle();
      expect(repo.updates, 1);
      expect(repo.deletions, ['old-photo']);
      expect(repo.creates, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('closing an edited form asks before discarding changes', (
    tester,
  ) async {
    await _mount(
      tester,
      SubmitListingPage(
        initialListing: _editable(),
        repository: SubmissionFake(),
        pickPhotos: () async => [],
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('Заголовок')),
      'Изменённое название квартиры',
    );
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    expect(
      find.text('Несохранённые изменения будут потеряны.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Изменённое название квартиры'), findsOneWidget);
  });
  testWidgets('edit route fetches full owner data before showing the form', (
    tester,
  ) async {
    final listings = OwnedListings();
    sl.registerSingleton<ListingsRepository>(listings);
    sl.registerSingleton(_api((o, h) => _reply(o, h, {})));
    await _mount(tester, EditListingPage(id: listings.item.id));
    expect(listings.loads, 1);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('Описание')))
          .controller!
          .text,
      listings.item.description,
    );
    expect(find.text('Сохранить изменения'), findsOneWidget);
  });
  testWidgets('edit does not expose the form for a different signed-in owner', (
    tester,
  ) async {
    await _mount(
      tester,
      SubmitListingPage(
        initialListing: _editable({'user_id': 'someone-else'}),
        repository: SubmissionFake(),
        pickPhotos: () async => [],
      ),
    );
    expect(find.text('Сохранить изменения'), findsNothing);
    expect(find.byKey(const ValueKey('Заголовок')), findsNothing);
  });
  testWidgets('my listing and owner detail both open the edit route', (
    tester,
  ) async {
    final listings = OwnedListings();
    sl.registerSingleton<ListingsRepository>(listings);
    sl.registerFactory(() => MyListingsCubit(listings));
    sl.registerSingleton(_api((o, h) => _reply(o, h, {})));
    final router = GoRouter(
      initialLocation: '/my-listings',
      routes: [
        GoRoute(
          path: '/my-listings',
          builder: (_, _) => const MyListingsPage(),
        ),
        GoRoute(
          path: '/my-listings/:id/edit',
          builder: (_, state) =>
              EditListingPage(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/my-listings/:id',
          builder: (_, state) => ListingDetailPage(
            listingId: state.pathParameters['id']!,
            owned: true,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _mount(
      tester,
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await _scroll(tester, find.text('Редактировать'));
    await tester.tap(find.text('Редактировать'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/my-listings/created-listing/edit');
    expect(find.text('Редактировать объявление'), findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/my-listings');
    router.go('/my-listings/created-listing');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Редактировать'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/my-listings/created-listing/edit');
    expect(tester.takeException(), isNull);
  });
  test('edit availability follows the server listing statuses', () {
    for (final status in ['active', 'pending', 'rejected']) {
      expect(_editable({'status': status}).canEdit, isTrue, reason: status);
    }
    for (final status in ['sold', 'removed', 'archived', 'draft']) {
      expect(_editable({'status': status}).canEdit, isFalse, reason: status);
    }
  });
  test('status changed on server produces a specific edit error', () async {
    final repo = SubmissionFake()
      ..createError = const AppException(
        'server message',
        code: 'INVALID_STATUS',
        statusCode: 409,
      );
    final submission = ListingSubmission(repo, listingId: 'created-listing');
    await submission.submit({}, []);
    expect(submission.error, 'В этом статусе объявление нельзя редактировать.');
    expect(submission.complete, isFalse);
    expect(repo.creates, 0);
    submission.dispose();
  });
  testWidgets('direct edit route refuses archived listings', (tester) async {
    final listings = OwnedListings()..item = _editable({'status': 'archived'});
    sl.registerSingleton<ListingsRepository>(listings);
    await _mount(tester, EditListingPage(id: listings.item.id));
    expect(find.text('Редактирование недоступно'), findsOneWidget);
    expect(find.text('Сохранить изменения'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });
  testWidgets('edit labels translate to Kyrgyz', (tester) async {
    await _mount(
      tester,
      SubmitListingPage(
        initialListing: _editable(),
        repository: SubmissionFake(),
        pickPhotos: () async => [],
      ),
      locale: const Locale('ky'),
    );
    expect(find.text('Жарыяны өзгөртүү'), findsOneWidget);
    expect(find.text('Өзгөртүүлөрдү сактоо'), findsOneWidget);
    await _snapshot(tester, 'edit-prefilled-ky');
  });
  testWidgets(
    'location picker selects a point and preserves it when reopened',
    (tester) async {
      await _mount(
        tester,
        SubmitListingPage(
          repository: SubmissionFake(),
          pickPhotos: () async => [],
        ),
      );
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
      await _scroll(tester, find.text('Указать место на карте'));
      await tester.tap(find.text('Указать место на карте'));
      await tester.pumpAndSettle();
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      final point = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers
          .single
          .point;
      await tester.tap(find.text('Выбрать это место'));
      await tester.pumpAndSettle();
      expect(find.text('Место на карте выбрано'), findsOneWidget);
      await tester.tap(find.text('Место на карте выбрано'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MarkerLayer>(find.byType(MarkerLayer))
            .markers
            .single
            .point,
        point,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new submission labels translate to Kyrgyz', (tester) async {
    await _mount(
      tester,
      SubmitListingPage(
        repository: SubmissionFake(),
        pickPhotos: () async => [],
      ),
      locale: const Locale('ky'),
    );
    expect(find.text('Кийинки'), findsOneWidget);
    await tester.tap(find.text('Кийинки'));
    await tester.pumpAndSettle();
    expect(find.text('Объект жөнүндө айтып бериңиз'), findsOneWidget);
    await _snapshot(tester, 'submission-fields-ky');
    await tester.tap(find.text('Текшерүүгө жөнөтүү'));
    await tester.pumpAndSettle();
    expect(find.text('Аталышы: 10дон 200гө чейин белги'), findsOneWidget);
  });
}
