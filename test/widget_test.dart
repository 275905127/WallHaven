import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallhaven/app/app.dart';
import 'package:wallhaven/theme/theme_store.dart';

void main() {
  testWidgets('app boots', (tester) async {
    final store = ThemeStore();

    await tester.pumpWidget(
      ThemeScope(
        store: store,
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('App'), findsOneWidget);
  });
}