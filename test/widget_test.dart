import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wallhaven/main.dart';
import 'package:wallhaven/theme/theme_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // ⚠️ shared_preferences 旧签名：Map<String, Object>
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('MyApp can build (smoke test)', (tester) async {
    final store = ThemeStore();

    await tester.pumpWidget(
      ThemeScope(
        store: store,
        child: MyApp(), // 如果 MyApp 不是 const，就去掉 const
      ),
    );

    // ThemeStore 会异步读 prefs，给它 settle 时间
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.byType(MyApp), findsOneWidget);
  });
}