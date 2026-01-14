import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  static SwitchThemeData _switchTheme(AppTokens tokens) {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? tokens.switchThumbOn
            : tokens.switchThumbOff;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.selected)
            ? tokens.switchTrackOn
            : tokens.switchTrackOff;
      }),
      trackOutlineColor:
          MaterialStatePropertyAll(tokens.switchTrackOutline),
      trackOutlineWidth:
          MaterialStatePropertyAll(tokens.switchTrackOutlineWidth),
      overlayColor: const MaterialStatePropertyAll(Colors.transparent),
    );
  }

  static SliderThemeData _sliderTheme(AppTokens tokens) {
    return SliderThemeData(
      trackHeight: tokens.sliderTrackHeight,
      thumbColor: tokens.sliderThumb,
      disabledThumbColor: tokens.sliderThumb,
      overlayColor: Colors.transparent,
      activeTrackColor: tokens.sliderTrackActive,
      inactiveTrackColor: tokens.sliderTrackInactive,
      disabledActiveTrackColor: tokens.sliderTrackActive,
      disabledInactiveTrackColor: tokens.sliderTrackInactive,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
    );
  }

  static ThemeData light(
    Color accentColor, {
    Color? customBg,
    Color? customCard,
    double cardRadius = 16,
  }) {
    final tokens = AppTokens.light();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor:
          customBg ?? AppColors.lightBackground,
      cardColor: customCard ?? AppColors.lightCard,

      // ❗ dividerColor 只兜底，真正设计全部走 tokens
      dividerColor: AppColors.lightDivider,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
      ),

      extensions: [tokens],

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightAlert,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightMenu,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      switchTheme: _switchTheme(tokens),
      sliderTheme: _sliderTheme(tokens),
    );
  }

  static ThemeData dark(
    Color accentColor, {
    Color? customBg,
    Color? customCard,
    double cardRadius = 16,
  }) {
    final tokens = AppTokens.dark();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor:
          customBg ?? AppColors.darkBackground,
      cardColor: customCard ?? AppColors.darkCard,

      dividerColor: AppColors.darkDivider,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        primary: accentColor,
      ),

      extensions: [tokens],

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkAlert,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkMenu,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      switchTheme: _switchTheme(tokens),
      sliderTheme: _sliderTheme(tokens),
    );
  }
}