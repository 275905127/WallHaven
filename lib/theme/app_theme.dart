// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static const Color _blackTrack = Color(0xFF0D0D0D);

  static SliderThemeData _sliderTheme() {
    return const SliderThemeData(
      trackHeight: 5, // ✅ 轨道加粗一点
      thumbColor: Colors.white, // ✅ 圆点白色
      overlayColor: Colors.transparent,
      activeTrackColor: _blackTrack, // ✅ 黑轨道（与自定义颜色开关同款黑）
      inactiveTrackColor: _blackTrack, // 需求是同款黑；如果要区分可改成带透明度
      inactiveTickMarkColor: Colors.transparent,
      activeTickMarkColor: Colors.transparent,
    );
  }

  static SwitchThemeData _switchThemeLight() {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((_) => Colors.white), // ✅ 圆点永远纯白
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return _blackTrack; // ✅ 选中：黑
        return const Color(0xFFE3E3E3); // 未选中：浅灰
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return Colors.transparent;
        return Colors.black.withOpacity(0.1);
      }),
      trackOutlineWidth: const MaterialStatePropertyAll(1.0),
    );
  }

  static SwitchThemeData _switchThemeDark() {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((_) => Colors.white), // ✅ 圆点永远纯白
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return _blackTrack; // ✅ 选中：黑
        return const Color(0xFF3B3B3B); // 未选中：深灰
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return Colors.transparent;
        return Colors.white.withOpacity(0.12);
      }),
      trackOutlineWidth: const MaterialStatePropertyAll(1.0),
    );
  }

  // ☀️ 浅色主题
  static ThemeData light(Color accentColor, {Color? customBg, Color? customCard, double cardRadius = 16.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: customBg ?? AppColors.lightBackground,
      cardColor: customCard ?? AppColors.lightCard,

      dialogBackgroundColor: AppColors.lightAlert,
      dividerColor: AppColors.lightDivider,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightAlert,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRadius))),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightMenu,
        surfaceTintColor: Colors.transparent,
        textStyle: const TextStyle(color: Colors.black, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRadius))),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ✅ 全局开关 & 滑块样式
      switchTheme: _switchThemeLight(),
      sliderTheme: _sliderTheme(),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Color(0xFF8E8E93)),
      ),
    );
  }

  // 🌙 深色主题
  static ThemeData dark(Color accentColor, {Color? customBg, Color? customCard, double cardRadius = 16.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: customBg ?? AppColors.darkBackground,
      cardColor: customCard ?? AppColors.darkCard,

      dialogBackgroundColor: AppColors.darkAlert,
      dividerColor: AppColors.darkDivider,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        primary: accentColor,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkAlert,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRadius))),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkMenu,
        surfaceTintColor: Colors.transparent,
        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRadius))),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // ✅ 全局开关 & 滑块样式
      switchTheme: _switchThemeDark(),
      sliderTheme: _sliderTheme(),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFF9E9E9E)),
      ),
    );
  }
}