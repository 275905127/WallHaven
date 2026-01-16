import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:your_app/main.dart' as app; // TODO: 改成你的包名路径

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    // main.dart 里如果有 ensureInitialized / runApp，在测试里不要直接调用 main()
    // 直接 pump root widget 最稳定。
    await tester.pumpWidget(const app.AppRoot()); // TODO: 改成你的根 Widget 名字
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}