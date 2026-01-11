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

  // 统一状态栏样式：透明沉浸式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent, // 底部导航条也透明 (Android 10+)
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

// === 1. 自定义全局滚动行为 (统一手感) ===
// 所有的 ListView/GridView 默认都拥有“阻尼回弹”效果，不用每个页面单独写
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
        const lightBg = Color(0xFFF1F1F3);     // 全局背景：冷灰白
        const lightSurface = Color(0xFFFFFDFD); // 卡片/弹窗：微暖白
        
        final darkBg = appState.useAmoled ? Colors.black : const Color(0xFF121212);
        final darkSurface = appState.useAmoled ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C);

        // 生成配色方案
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

        // === 3. 统一形状 (圆角系统) ===
        // 改这里，全App所有卡片和弹窗的圆角都会变
        const commonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)), 
        );
        
        // === 4. 统一转场动画 ===
        // 类似 Android 10+ 的缩放淡入淡出，或者 iOS 的侧滑
        const pageTransitions = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(), // 现代安卓风格
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), // 经典 iOS 侧滑
          },
        );

        // === 5. 统一字体样式 (TextTheme) ===
        // 预设好标题和正文样式，页面里直接用 Theme.of(context).textTheme.titleLarge
        // 这样以后想换字体或改大小，改这里就行
        final textThemeBase = Theme.of(context).textTheme;
        final appTextTheme = textThemeBase.copyWith(
          titleLarge: textThemeBase.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: textThemeBase.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          bodyMedium: textThemeBase.bodyMedium?.copyWith(fontSize: 14),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Wallhaven Client',
          
          // 注入全局滚动行为
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
            textTheme: appTextTheme, // 应用统一字体
            pageTransitionsTheme: pageTransitions, // 应用统一转场

            appBarTheme: AppBarTheme(
              backgroundColor: lightBg,
              scrolledUnderElevation: 0,
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            
            cardTheme: const CardTheme(
              color: lightSurface, 
              elevation: 0, 
              margin: EdgeInsets.zero, 
              shape: commonShape
            ),
            
            dialogTheme: const DialogTheme(
              backgroundColor: lightSurface,
              elevation: 4,
              shape: commonShape,
              titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),

            // 按钮样式统一
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
            textTheme: appTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white), // 字体自动变白
            pageTransitionsTheme: pageTransitions,

            appBarTheme: AppBarTheme(
              backgroundColor: darkBg,
              scrolledUnderElevation: 0,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            
            cardTheme: CardTheme(
              color: darkSurface, 
              elevation: 0, 
              margin: EdgeInsets.zero, 
              shape: commonShape
            ),
            
            dialogTheme: DialogTheme(
              backgroundColor: darkSurface,
              shape: commonShape,
              titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),

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
