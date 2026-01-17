import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wallhaven/theme/theme_store.dart';
import 'package:wallhaven/theme/theme_scope.dart';
import 'package:wallhaven/main.dart';

void main() {
  testWidgets('App root can build (smoke test)', (tester) async {
    final themeStore = ThemeStore();

    await tester.pumpWidget(
      ThemeScope(
        store: themeStore,
        child: MyApp(),
      ),
    );

    // 关键：让首帧 + 一次 build 走完
    await tester.pump();
  });
}