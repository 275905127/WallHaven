// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  static SwitchThemeData _switchTheme(AppTokens tokens) {
    // ✅ 圆点永远纯白
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((_) => tokens.controlThumb),
      trackColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? tokens.controlTrackActive
            : tokens.controlTrackInactive;
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((_) => Colors.transparent),
      trackOutlineWidth: const MaterialStatePropertyAll(0.0),
      overlayColor: const MaterialStatePropertyAll(Colors.transparent),
    );
  }

  static SliderThemeData _sliderTheme(AppTokens tokens) {
    // ✅ 圆点白、轨道黑、轨道加粗
    return SliderThemeData(
      trackHeight: tokens.sliderTrackHeight,
      thumbColor: tokens.controlThumb,
      overlayColor: Colors.transparent,
      activeTrackColor: tokens.controlTrackActive,
      inactiveTrackColor: tokens.controlTrackActive, // 同款黑
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      disabledActiveTrackColor: tokens.controlTrackActive,
      disabledInactiveTrackColor: tokens.controlTrackActive,
      disabledThumbColor: tokens.controlThumb,
    );
  }

  static ThemeData light(Color accentColor, {Color? customBg, Color? customCard, double cardRadius = 16.0}) {
    final tokens = AppTokens.light();
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

      extensions: <ThemeExtension<dynamic>>[
        tokens,
      ],

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

      // ✅ 全局控件皮肤统一出口
      switchTheme: _switchTheme(tokens),
      sliderTheme: _sliderTheme(tokens),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Color(0xFF8E8E93)),
      ),
    );
  }

  static ThemeData dark(Color accentColor, {Color? customBg, Color? customCard, double cardRadius = 16.0}) {
    final tokens = AppTokens.dark();
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

      extensions: <ThemeExtension<dynamic>>[
        tokens,
      ],

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

      switchTheme: _switchTheme(tokens),
      sliderTheme: _sliderTheme(tokens),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFF9E9E9E)),
      ),
    );
  }
}