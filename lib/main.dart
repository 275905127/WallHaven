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
        const lightBg = Color(0xFFF1F1F3);
        const lightSurface = Colors.white; // 弹窗保持纯白

        // 统一圆角（复刻图中大圆角）
        const commonRadius = Radius.circular(32);
        const commonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(commonRadius),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          locale: appState.locale,
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, surface: lightSurface),
            scaffoldBackgroundColor: lightBg,
            
            // 弹窗主题：底部悬浮
            dialogTheme: DialogThemeData(
              backgroundColor: lightSurface,
              elevation: 0,
              shape: commonShape,
              alignment: Alignment.bottomCenter,
              actionsPadding: EdgeInsets.zero, // 我们在子组件里自定义 padding
            ),

            // 复刻 GIF 里的按钮按压效果
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                // 按压时的灰色水波纹
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                // 关键：复刻 GIF 中按压时那种带圆角的反馈形状
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            cardTheme: const CardTheme(
              color: lightSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
            ),
          ),
          themeMode: appState.themeMode,
          home: const HomePage(),
        );
      },
    );
  }

