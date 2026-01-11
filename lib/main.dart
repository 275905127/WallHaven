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

  // 统一状态栏样式
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

// === 1. 自定义全局滚动行为 ===
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
        // === 2. 统一颜色定义 ===
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

        // === 3. 统一形状 ===
        const commonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)), 
        );
        
        // === 4. 统一转场动画 ===
        const pageTransitions = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        );

        // === 5. 统一字体样式 ===
        final textThemeBase = Theme.of(context).textTheme;
        final appTextTheme = textThemeBase.copyWith(
          titleLarge: textThemeBase.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: textThemeBase.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          bodyMedium: textThemeBase.bodyMedium?.copyWith(fontSize: 14),
        );

        // 【修复点】：使用 DialogThemeData 替代 DialogTheme
        final dialogThemeLight = DialogThemeData(
          backgroundColor: lightSurface,
          elevation: 0,
          shape: commonShape,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          contentTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
        
        final dialogThemeDark = DialogThemeData(
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
            
            // 【修复点】：使用 CardThemeData
            cardTheme: CardThemeData(
              color: lightSurface, 
              elevation: 0, 
              margin: EdgeInsets.zero, 
              shape: commonShape
            ),
            
            dialogTheme: dialogThemeLight,

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              )
            ),
            
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: lightSurface,
              modalBackgroundColor: lightSurface,
              shape: commonShape,
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
            
            // 【修复点】：使用 CardThemeData
            cardTheme: CardThemeData(
              color: darkSurface, 
              elevation: 0, 
              margin: EdgeInsets.zero, 
              shape: commonShape
            ),
            
            dialogTheme: dialogThemeDark,

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              )
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
