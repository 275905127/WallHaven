// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wallhaven/main.dart';
import 'package:wallhaven/theme/theme_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // shared_preferences 旧签名：Map<String, Object>
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('App root can build (smoke test)', (tester) async {
    final store = ThemeStore();

    await tester.pumpWidget(
      ThemeScope(
        store: store,
        child: MaterialApp(
          home: const HomePage(),
        ),
      ),
    );

    // 给首帧 + 一次 settle（别无限 settle）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 只验证：HomePage 成功进入树里
    expect(find.byType(HomePage), findsOneWidget);
  });
}