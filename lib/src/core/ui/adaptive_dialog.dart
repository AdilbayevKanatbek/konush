import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _usesCupertino => defaultTargetPlatform == TargetPlatform.iOS;

final _dialogOpen = Expando<bool>();

Future<bool> showAdaptiveConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Отмена',
  bool destructive = false,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (_dialogOpen[navigator] == true) return false;
  _dialogOpen[navigator] = true;
  try {
    return await _showConfirmation(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    );
  } finally {
    _dialogOpen[navigator] = false;
  }
}

Future<bool> _showConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Отмена',
  bool destructive = false,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();

  if (_usesCupertino) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr(cancelLabel)),
              ),
              CupertinoDialogAction(
                isDestructiveAction: destructive,
                isDefaultAction: !destructive,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr(cancelLabel)),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD3483E),
                    )
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

class AdaptiveActivityIndicator extends StatelessWidget {
  const AdaptiveActivityIndicator({super.key, this.dimension = 24});

  final double dimension;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: dimension,
    child: _usesCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator(strokeWidth: 2.5),
  );
}
