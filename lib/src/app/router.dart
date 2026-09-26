import 'package:flutter/foundation.dart';
import 'package:konush/src/features/chat/domain/chat_models.dart';
import 'package:konush/src/features/chat/presentation/chat_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/features/auth/presentation/pages/login_page.dart';
import 'package:konush/src/features/auth/presentation/pages/auth_flow_pages.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';
import 'package:konush/src/features/listings/presentation/pages/listing_detail_page.dart';
import 'package:konush/src/features/listings/presentation/pages/favorites_page.dart';
import 'package:konush/src/features/listings/presentation/pages/my_listings_page.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/home/presentation/home_page.dart';
import 'package:konush/src/core/ui/app_motion.dart';
import 'package:konush/src/features/complexes/presentation/complexes_page.dart';
import 'package:konush/src/features/home/presentation/mobile_pages.dart';
import 'package:konush/src/features/listings/presentation/pages/submit_listing_page.dart';
import 'package:konush/src/features/listings/presentation/pages/edit_listing_page.dart';
import 'package:konush/src/features/complexes/presentation/construction_financing.dart';
import 'package:konush/src/features/complexes/presentation/construction_contacts.dart';

Page<void> _page(
  GoRouterState state,
  Widget child, {
  String? fallback,
  bool handlesBack = false,
}) {
  final content = handlesBack
      ? child
      : PageBackScope(fallback: fallback, child: child);
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: content);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: content,
    transitionDuration: AppMotion.standard,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enterCurve,
        reverseCurve: AppMotion.exitCurve,
      );
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .012),
            end: Offset.zero,
          ).animate(fade),
          child: child,
        ),
      );
    },
  );
}

GoRouter createAppRouter({String initialLocation = '/'}) {
  GoRoute screen(
    String path,
    Widget Function(GoRouterState) build, {
    String? fallback,
    bool handlesBack = false,
  }) => GoRoute(
    path: path,
    pageBuilder: (_, state) => _page(
      state,
      build(state),
      fallback: fallback,
      handlesBack: handlesBack,
    ),
  );
  StatefulShellBranch branch(List<RouteBase> routes) => StatefulShellBranch(
    observers: [DismissKeyboardObserver()],
    routes: routes,
  );
  return GoRouter(
    initialLocation: initialLocation,
    observers: [DismissKeyboardObserver()],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) => KonushShell(
          path: state.uri.path,
          navigationShell: shell,
          child: shell,
        ),
        branches: [
          branch([
            screen('/', (_) => const HomePage()),
            screen(
              '/listings',
              (state) => ListingsPage(
                initialTab: switch (state.uri.queryParameters['tab']) {
                  'rent' => CatalogTab.rent,
                  'new' => CatalogTab.newBuilds,
                  _ => CatalogTab.buy,
                },
              ),
              fallback: '/',
            ),
            screen('/complexes', (_) => const ComplexesPage(), fallback: '/'),
            screen(
              '/complexes/:id',
              (state) => ComplexDetailPage(id: state.pathParameters['id']!),
              fallback: '/complexes',
            ),
            screen(
              '/complexes/:id/units',
              (state) => UnitCatalogPage(
                complexId: state.pathParameters['id']!,
                initial: {
                  if ([
                    'apartment',
                    'office',
                    'parking',
                  ].contains(state.uri.queryParameters['unit_type']))
                    'unit_type': state.uri.queryParameters['unit_type'],
                  if (int.tryParse(state.uri.queryParameters['rooms'] ?? '')
                      case final int rooms when rooms >= 0 && rooms <= 20)
                    'rooms': rooms,
                  if ([
                    'available',
                    'reserved',
                    'sold',
                  ].contains(state.uri.queryParameters['sale_status']))
                    'sale_status': state.uri.queryParameters['sale_status'],
                },
              ),
              fallback: '/complexes',
            ),
            screen(
              '/complexes/:id/units/:unitId',
              (state) => UnitDetailPage(
                id: state.pathParameters['unitId']!,
                complexId: state.pathParameters['id']!,
              ),
              fallback: '/complexes',
            ),
            screen(
              '/units/:id',
              (state) => UnitDetailPage(id: state.pathParameters['id']!),
              fallback: '/complexes',
            ),
            screen(
              '/companies/:id',
              (state) => CompanyPage(id: state.pathParameters['id']!),
              fallback: '/complexes',
            ),
            screen(
              '/mortgage',
              (_) => const MortgagePage(),
              fallback: '/complexes',
            ),
          ]),
          branch([screen('/favorites', (_) => const FavoritesPage())]),
          branch([screen('/messages', (_) => const MessagesPage())]),
          branch([
            screen('/profile', (_) => const AccountPage()),
            screen(
              '/settings',
              (_) => const SettingsPage(),
              fallback: '/profile',
            ),
            screen(
              '/my-listings',
              (_) => const MyListingsPage(),
              fallback: '/profile',
            ),
            screen(
              '/my-requests',
              (_) => const MyRequestsPage(),
              fallback: '/profile',
            ),
          ]),
        ],
      ),
      screen('/login', (_) => const LoginPage(), fallback: '/profile'),
      screen(
        '/register',
        (_) => const LoginPage(register: true),
        fallback: '/login',
      ),
      screen(
        '/verify-phone',
        (state) => CodePage(
          phone: state.uri.queryParameters['phone'] ?? '',
          purpose: CodePurpose.verifyPhone,
        ),
        fallback: '/login',
      ),
      screen(
        '/forgot-password',
        (_) => const ForgotPasswordPage(),
        fallback: '/login',
      ),
      screen(
        '/reset-code',
        (state) => CodePage(
          phone: state.uri.queryParameters['phone'] ?? '',
          purpose: CodePurpose.resetPassword,
        ),
        fallback: '/forgot-password',
      ),
      screen(
        '/new-password',
        (state) => NewPasswordPage(
          phone: state.uri.queryParameters['phone'] ?? '',
          token: state.uri.queryParameters['token'] ?? '',
        ),
        fallback: '/login',
      ),
      screen('/support', (_) => const SupportPage(), fallback: '/messages'),
      screen(
        '/submit',
        (_) => const SubmitListingPage(),
        fallback: '/profile',
        handlesBack: true,
      ),
      screen(
        '/my-listings/:id/edit',
        (state) => EditListingPage(id: state.pathParameters['id']!),
        fallback: '/my-listings',
        handlesBack: true,
      ),
      screen(
        '/my-listings/:id',
        (state) => ListingDetailPage(
          listingId: state.pathParameters['id']!,
          owned: true,
        ),
        fallback: '/my-listings',
      ),
      screen(
        '/listings/:id',
        (state) => ListingDetailPage(
          listingId: state.pathParameters['id']!,
          initialListing: state.extra is Listing
              ? state.extra! as Listing
              : null,
        ),
        fallback: '/listings',
      ),
      screen(
        '/messages/:id',
        (state) => ConversationPage(
          id: state.pathParameters['id']!,
          initial: state.extra is Conversation
              ? state.extra! as Conversation
              : null,
        ),
        fallback: '/messages',
      ),
    ],
  );
}

final appRouter = createAppRouter();
