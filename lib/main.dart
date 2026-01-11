import 'dart:io'; // <--- 1. 引入 IO 库
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // === 2. 启用全局 SSL 忽略 (解决 VPN 问题) ===
  HttpOverrides.global = MyHttpOverrides(); 

  final appState = AppState();
  await appState.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
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

// === 3. 定义覆盖类 ===
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // 核心逻辑：直接返回 true，信任所有证书（包括 VPN 的自签名证书）
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// === 全局滚动行为 ===
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // === 1. 统一颜色 ===
        const lightBg = Color(0xFFF1F1F3);
        const lightSurface = Color(0xFFFFFDFD);
        
        final darkBg = appState.useAmoled ? Colors.black : const Color(0xFF121212);
        final darkSurface = appState.useAmoled ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C);

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

        // === 2. 统一形状 (动态读取设置) ===
        final commonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(appState.cornerRadius)), 
        );
        
        // === 3. 统一转场动画 ===
        const pageTransitions = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        );

        // === 4. 统一字体 ===
        final textThemeBase = Theme.of(context).textTheme;
        final appTextTheme = textThemeBase.copyWith(
          titleLarge: textThemeBase.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: textThemeBase.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          bodyMedium: textThemeBase.bodyMedium?.copyWith(fontSize: 14),
        );

        // === 5. 统一弹窗样式 ===
        final dialogThemeLight = DialogThemeData(
          backgroundColor: lightSurface,
          elevation: 0,
          shape: commonShape,
          alignment: Alignment.bottomCenter, 
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          contentTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24), 
        );
        
        final dialogThemeDark = DialogThemeData(
          backgroundColor: darkSurface,
          elevation: 0,
          shape: commonShape,
          alignment: Alignment.bottomCenter, 
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white70),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Wallhaven Client',
          scrollBehavior: AppScrollBehavior(),
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
            textTheme: appTextTheme,
            pageTransitionsTheme: pageTransitions,

            appBarTheme: AppBarTheme(
              backgroundColor: lightBg,
              scrolledUnderElevation: 0,
              titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            
            cardTheme: CardThemeData(
              color: lightSurface, 
              elevation: 0, 
              margin: EdgeInsets.zero, 
              shape: commonShape
            ),
            
            dialogTheme: dialogThemeLight,

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              )
            ),
            
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: lightSurface,
              modalBackgroundColor: lightSurface,
              shape: commonShape,
            ),
            
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              isDense: true,
            ),
          ),

          // === 深色主题 ===
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkBg,
            textTheme: appTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
            pageTransitionsTheme: pageTransitions,

            appBarTheme: AppBarTheme(
              backgroundColor: darkBg,
              scrolledUnderElevation: 0,
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            
            cardTheme: CardThemeData(
              color: darkSurface, 
              elevation: 0, 
              margin: EdgeInsets.zero, 
              shape: commonShape
            ),
            
            dialogTheme: dialogThemeDark,

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              )
            ),
            
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: darkSurface,
              modalBackgroundColor: darkSurface,
              shape: commonShape,
            ),
            
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              isDense: true,
            ),
          ),
          
          themeMode: appState.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
