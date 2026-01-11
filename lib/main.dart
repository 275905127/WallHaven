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
        // 浅色模式
        const lightBg = Color(0xFFF1F1F3); // 全局背景：冷灰白
        const lightSurface = Color(0xFFFFFDFD); // 卡片/弹窗：微暖白
        
        // 深色模式 (普通深灰 vs AMOLED纯黑)
        final darkBg = appState.useAmoled ? Colors.black : const Color(0xFF121212);
        final darkSurface = appState.useAmoled ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C);

        // 2. 生成配色方案 (混合动态取色)
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && appState.useMaterialYou) {
          lightScheme = lightDynamic.harmonized();
          // 强制覆盖动态取色里的背景和表面色，保持我们要的风格
          lightScheme = lightScheme.copyWith(surface: lightSurface, surfaceContainerHighest: lightSurface);
          
          darkScheme = darkDynamic?.harmonized() ?? const ColorScheme.dark();
          darkScheme = darkScheme.copyWith(surface: darkSurface, surfaceContainerHighest: darkSurface);
        } else {
          lightScheme = ColorScheme.fromSeed(seedColor: Colors.blue, surface: lightSurface);
          darkScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark, surface: darkSurface);
        }

        // 3. 定义统一的形状 (圆角 24)
        const commonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
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

          // === 浅色主题配置 ===
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            scaffoldBackgroundColor: lightBg,
            
            // 顶部栏透明
            appBarTheme: AppBarTheme(
              backgroundColor: lightBg,
              scrolledUnderElevation: 0,
            ),
            
            // 统一卡片样式
            cardTheme: const CardTheme(
              color: lightSurface,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: commonShape,
            ),
            
            // 统一 Dialog (中间弹窗) 样式
            dialogTheme: const DialogTheme(
              backgroundColor: lightSurface,
              elevation: 4,
              shape: commonShape,
            ),
            
            // 统一 BottomSheet (底部弹窗) 样式
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: lightSurface,
              modalBackgroundColor: lightSurface,
              elevation: 4,
              shape: commonShape,
            ),
          ),

          // === 深色主题配置 ===
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkBg,
            
            appBarTheme: AppBarTheme(
              backgroundColor: darkBg,
              scrolledUnderElevation: 0,
            ),
            
            cardTheme: CardTheme(
              color: darkSurface,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: commonShape,
            ),
            
            dialogTheme: DialogTheme(
              backgroundColor: darkSurface,
              shape: commonShape,
            ),
            
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: darkSurface,
              modalBackgroundColor: darkSurface,
              shape: commonShape,
            ),
          ),
          
          themeMode: appState.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
