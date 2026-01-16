import 'package:flutter_test/flutter_test.dart';
import 'package:wallhaven/main.dart';

void main() {
  testWidgets('MyApp can build (smoke test)', (tester) async {
    // 只保证应用能启动并渲染一帧，不绑定任何具体页面/控件结构
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}