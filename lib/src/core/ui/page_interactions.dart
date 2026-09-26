import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/ui/adaptive_dialog.dart';

/// Uses Flutter's text-field tap regions: buttons still receive the same tap,
/// and tapping another field transfers focus normally.
class AppInputActions extends StatelessWidget {
  const AppInputActions({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
    },
    child: child,
  );
}

class DismissKeyboardObserver extends NavigatorObserver {
  void _dismiss() => FocusManager.instance.primaryFocus?.unfocus();
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _dismiss();
}

class PageBackScope extends StatefulWidget {
  const PageBackScope({super.key, required this.child, this.fallback});
  final Widget child;

  /// null denotes a main tab, where Back really leaves Android.
  final String? fallback;
  @override
  State<PageBackScope> createState() => _PageBackScopeState();
}

class _PageBackScopeState extends State<PageBackScope> {
  bool _confirming = false;
  @override
  Widget build(BuildContext context) {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final first = ModalRoute.of(context)?.isFirst ?? false;
    return PopScope<Object?>(
      canPop: !android || (!keyboard && !first),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !android || _confirming) return;
        if (keyboard) {
          FocusManager.instance.primaryFocus?.unfocus();
          await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          return;
        }
        if (!first) return;
        if (widget.fallback != null) {
          context.go(widget.fallback!);
          return;
        }
        _confirming = true;
        try {
          final exit = await showAdaptiveConfirmationDialog(
            context: context,
            title: context.tr("Выйти из приложения?"),
            message: context.tr("Вы сможете вернуться в Konush в любое время."),
            confirmLabel: context.tr("Выйти"),
          );
          if (exit && mounted) await SystemNavigator.pop();
        } finally {
          _confirming = false;
        }
      },
      child: widget.child,
    );
  }
}

final _openRoutes = Expando<Set<String>>();

Future<T?> openPage<T>(
  BuildContext context,
  String location, {
  Object? extra,
}) async {
  final router = GoRouter.of(context);
  final pending = _openRoutes[router] ??= <String>{};
  if (router.state.uri.toString() == location || !pending.add(location)) {
    return null;
  }
  FocusManager.instance.primaryFocus?.unfocus();
  late final Future<T?> result;
  try {
    result = router.push<T>(location, extra: extra);
    // Block duplicate taps only while navigation is being applied. A later
    // go() can replace the stack without completing the original push future.
    await WidgetsBinding.instance.endOfFrame;
  } finally {
    pending.remove(location);
  }
  return result;
}
