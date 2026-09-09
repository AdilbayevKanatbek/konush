import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/core/ui/adaptive_dialog.dart';

void main() {
  testWidgets('uses a Material dialog on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const _DialogHarness());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('uses a Cupertino dialog on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(const _DialogHarness());

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness();

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showAdaptiveConfirmationDialog(
            context: context,
            title: 'Exit?',
            message: 'Confirm exit',
            confirmLabel: 'Exit',
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}
