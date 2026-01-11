import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 1. 定义核心颜色
        const lightBg = Color(0xFFF1F1F3); // 全局背景
        const lightSurface = Color(0xFFFFFDFD); // 卡片/弹窗颜色
        
        final darkBg = appState.useAmoled ? Colors.black : const Color(0xFF121212);
        final darkSurface = appState.useAmoled ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C);

        // 2. 生成配色
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && appState.useMaterialYou) {
          lightScheme = lightDynamic.harmonized();
          lightScheme = lightScheme.copyWith(surface: lightSurface, surfaceContainerHighest: lightSurface);
          
          darkScheme = darkDynamic?.harmonized() ?? const ColorScheme.dark();
          darkScheme = darkScheme.copyWith(surface: darkSurface, surfaceContainerHighest: darkSurface);
        } else {
          lightScheme = ColorScheme.fromSeed(seedColor: Colors.blue, surface: lightSurface);
          darkScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark, surface: darkSurface);
        }

        // 3. 统一形状：参考图的大圆角 (28px)
        const commonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        );

        // 4. 统一 Dialog 主题 (关键！)
        // 这会让所有 AlertDialog 自动变成参考图的样式
        final dialogThemeLight = DialogTheme(
          backgroundColor: lightSurface,
          elevation: 0,
          shape: commonShape,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          contentTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
          // 按钮均匀分布
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
        
        final dialogThemeDark = DialogTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          shape: commonShape,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white70),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Wallhaven Client',
          locale: appState.locale,
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // === 浅色主题 ===
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            scaffoldBackgroundColor: lightBg,
            appBarTheme: AppBarTheme(backgroundColor: lightBg, scrolledUnderElevation: 0),
            cardTheme: const CardTheme(color: lightSurface, elevation: 0, margin: EdgeInsets.zero, shape: commonShape),
            dialogTheme: dialogThemeLight,
            // 确保 AlertDialog 内部按钮对齐
            timePickerTheme: TimePickerThemeData(shape: commonShape, backgroundColor: lightSurface),
          ),

          // === 深色主题 ===
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkBg,
            appBarTheme: AppBarTheme(backgroundColor: darkBg, scrolledUnderElevation: 0),
            cardTheme: CardTheme(color: darkSurface, elevation: 0, margin: EdgeInsets.zero, shape: commonShape),
            dialogTheme: dialogThemeDark,
          ),
          
          themeMode: appState.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
