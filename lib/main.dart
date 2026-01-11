import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 如果报错，请运行 flutter pub add flutter_localizations

import 'providers.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init(); // 等待本地配置读取完成

  // 设置沉浸式状态栏
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
        // 构建配色方案
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && appState.useMaterialYou) {
          // 开启了动态取色
          lightScheme = lightDynamic.harmony();
          darkScheme = darkDynamic?.harmony() ?? const ColorScheme.dark();
        } else {
          // 未开启或不支持，使用默认蓝色
          lightScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Wallhaven Client',
          
          // 语言支持
          locale: appState.locale,
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // 浅色主题
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            scaffoldBackgroundColor: const Color(0xFFF2F2F2), // 经典灰白底
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF2F2F2),
              scrolledUnderElevation: 0,
            ),
          ),

          // 深色主题
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            // 核心功能：如果是 AMOLED 模式，背景纯黑，否则用深灰
            scaffoldBackgroundColor: appState.useAmoled ? Colors.black : const Color(0xFF121212),
            appBarTheme: AppBarTheme(
              backgroundColor: appState.useAmoled ? Colors.black : const Color(0xFF121212),
              scrolledUnderElevation: 0,
            ),
          ),
          
          // 当前主题模式
          themeMode: appState.themeMode,
          
          home: const HomePage(),
        );
      },
    );
  }
}
