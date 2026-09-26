import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/ui/page_interactions.dart';

void main() {
  testWidgets(
    'rapid duplicate taps push once and the caller receives the result',
    (tester) async {
      final results = <int?>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    results.add(await openPage<int>(context, '/child')),
                child: const Text('Open'),
              ),
            ),
          ),
          GoRoute(
            path: '/child',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(42),
                child: const Text('Return'),
              ),
            ),
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      });
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/child');
      expect(results, [null]);
      await tester.tap(find.text('Return'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      expect(router.canPop(), isFalse);
      expect(results, [null, 42]);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return'));
      await tester.pumpAndSettle();
      expect(results, [null, 42, 42]);
    },
  );
}
