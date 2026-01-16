import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TODO: 把 wallhaven 改成 pubspec.yaml 里的 name
import 'package:wallhaven/main.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    // 如果你 main.dart 里有 AppRoot / MyApp，二选一
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}