import 'package:konush/l10n/locale_cubit.dart';
import 'package:konush/l10n/generated/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/features/chat/presentation/chat_cubit.dart';
import 'package:konush/src/features/chat/presentation/chat_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/app/router.dart';
import 'package:konush/src/app/theme.dart';
import 'package:konush/src/core/ui/page_interactions.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';

class KonushApp extends StatelessWidget {
  const KonushApp({super.key, this.router, this.theme});
  final GoRouter? router;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocaleCubit(const FlutterSecureStorage())..restore(),
        ),
        BlocProvider(create: (_) => sl<AuthCubit>()..restoreSession()),
        BlocProvider(create: (_) => sl<FavoritesCubit>()..restore()),
        BlocProvider(create: (_) => sl<ChatCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.user?.id != current.user?.id ||
            current.status == AuthStatus.unauthenticated,
        listener: (context, state) async {
          final favorites = context.read<FavoritesCubit>();
          await favorites.setUser(state.user?.id);
          if (!favorites.isClosed && state.status == AuthStatus.authenticated) {
            await favorites.load();
          }
        },
        child: ChatSession(
          child: BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => MaterialApp.router(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              title: 'Konush',
              debugShowCheckedModeBanner: false,
              theme: theme ?? AppTheme.light,
              routerConfig: router ?? appRouter,
              builder: (context, child) =>
                  AppInputActions(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}
