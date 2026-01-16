import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wallhaven/main.dart';
import 'package:wallhaven/theme/theme_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object?>{});
  });

  testWidgets('MyApp can build (smoke test)', (tester) async {
    final store = ThemeStore();

    await tester.pumpWidget(
      ThemeScope(
        store: store,
        child: const MyApp(),
      ),
    );

    // ThemeStore 会异步 load prefs，给它一点 settle 时间
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.byType(MyApp), findsOneWidget);
  });
}