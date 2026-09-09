import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/app/router.dart';
import 'package:konush/src/app/theme.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';

class KonushApp extends StatelessWidget {
  const KonushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()..restoreSession()),
        BlocProvider(create: (_) => sl<FavoritesCubit>()..restore()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != AuthStatus.authenticated &&
            current.status == AuthStatus.authenticated,
        listener: (context, _) =>
            context.read<FavoritesCubit>().syncWithServer(),
        child: MaterialApp.router(
          title: 'Konush',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
          builder: (context, child) => Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              final focus = FocusManager.instance.primaryFocus;
              if (focus != null && !focus.hasPrimaryFocus) focus.unfocus();
            },
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
