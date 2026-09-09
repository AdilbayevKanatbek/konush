import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

CustomTransitionPage<void> _page(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.standard,
      reverseTransitionDuration: AppMotion.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          return CupertinoPageTransition(
            primaryRouteAnimation: animation,
            secondaryRouteAnimation: secondaryAnimation,
            linearTransition: false,
            child: child,
          );
        }
        final fade = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enterCurve,
          reverseCurve: AppMotion.exitCurve,
        );
        final slide = Tween(
          begin: const Offset(0, .012),
          end: Offset.zero,
        ).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (_, state) => _page(state, const HomePage()),
    ),
    GoRoute(
      path: '/listings',
      pageBuilder: (_, state) => _page(
        state,
        ListingsPage(
          initialTab: switch (state.uri.queryParameters['tab']) {
            'rent' => CatalogTab.rent,
            'new' => CatalogTab.newBuilds,
            _ => CatalogTab.buy,
          },
        ),
      ),
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (_, state) => _page(state, const FavoritesPage()),
    ),
    GoRoute(
      path: '/complexes',
      pageBuilder: (_, state) => _page(state, const ComplexesPage()),
    ),
    GoRoute(
      path: '/complexes/:id',
      pageBuilder: (_, state) =>
          _page(state, ComplexDetailPage(id: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/my-listings',
      pageBuilder: (_, state) => _page(state, const MyListingsPage()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (_, state) => _page(state, const LoginPage()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (_, state) => _page(state, const LoginPage(register: true)),
    ),
    GoRoute(
      path: '/verify-phone',
      pageBuilder: (_, state) => _page(
        state,
        CodePage(
          phone: state.uri.queryParameters['phone'] ?? '',
          purpose: CodePurpose.verifyPhone,
        ),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (_, state) => _page(state, const ForgotPasswordPage()),
    ),
    GoRoute(
      path: '/reset-code',
      pageBuilder: (_, state) => _page(
        state,
        CodePage(
          phone: state.uri.queryParameters['phone'] ?? '',
          purpose: CodePurpose.resetPassword,
        ),
      ),
    ),
    GoRoute(
      path: '/new-password',
      pageBuilder: (_, state) => _page(
        state,
        NewPasswordPage(
          phone: state.uri.queryParameters['phone'] ?? '',
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (_, state) => _page(state, const ProfilePage()),
    ),
    GoRoute(
      path: '/listings/:id',
      pageBuilder: (_, state) => _page(
        state,
        ListingDetailPage(
          listingId: state.pathParameters['id']!,
          initialListing: state.extra is Listing
              ? state.extra! as Listing
              : null,
        ),
      ),
    ),
  ],
);
