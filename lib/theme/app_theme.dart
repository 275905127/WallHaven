import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

// =============================================================
// ⚠️ DESIGN GUARD — 绝对禁止私自改动 ⚠️
//
// 本文件中的视觉行为（颜色 / 圆角 / 分割 / 动画）
// 统一由 AppTokens 作为【唯一设计源】提供。
//
// ❌ 禁止行为：
// - 在 Theme / Widget 中硬编码颜色、半透明值、尺寸
// - 擅自“优化”“微调”“感觉更好看”的任何视觉改动
// - 绕过 tokens 直接改 Switch / Slider / Divider 表现
//
// ✅ 正确做法：
// - 只能改 AppTokens
// - tokens 不够用 → 先加语义字段，再全局替换
//
// ⚠️ 任何未经允许的视觉改动，
// 都会被视为【破坏设计基线】而回滚。
//
// —— 写给未来的你，也写给现在这个手欠的我
// =============================================================

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
      trackOutlineColor: MaterialStatePropertyAll(tokens.switchTrackOutline),
      trackOutlineWidth: MaterialStatePropertyAll(tokens.switchTrackOutlineWidth),
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

  // ✅ 全局卡片圆角：统一出口（不影响图片圆角）
  static RoundedRectangleBorder _cardShape(double cardRadius) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    );
  }

  // ✅ Drawer 圆角：跟随全局卡片圆角（抽屉页跟随 cardRadius）
  static RoundedRectangleBorder _drawerShape(double cardRadius) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    );
  }

  static ThemeData light(
    Color accentColor, {
    Color? customBg,
    Color? customCard,
    double cardRadius = 16,
  }) {
    final tokens = AppTokens.light();
    final cardShape = _cardShape(cardRadius);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: customBg ?? AppColors.lightBackground,
      cardColor: customCard ?? AppColors.lightCard,

      // ❗ dividerColor 只兜底，真正设计全部走 tokens
      dividerColor: AppColors.lightDivider,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
      ),

      extensions: [tokens],

      // ✅ Flutter 3.27+ 这里要用 CardThemeData（不是 CardTheme）
      cardTheme: CardThemeData(shape: cardShape),

      // ✅ 抽屉整体圆角跟随全局 cardRadius
      drawerTheme: DrawerThemeData(shape: _drawerShape(cardRadius)),

      // ✅ 长条选择弹窗/底部弹层也一起收敛到全局圆角
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),

      // ✅ Flutter 3.27+ 这里要用 DialogThemeData（不是 DialogTheme）
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightAlert,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightMenu,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
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
    final cardShape = _cardShape(cardRadius);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: customBg ?? AppColors.darkBackground,
      cardColor: customCard ?? AppColors.darkCard,

      dividerColor: AppColors.darkDivider,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        primary: accentColor,
      ),

      extensions: [tokens],

      // ✅ Flutter 3.27+：CardThemeData
      cardTheme: CardThemeData(shape: cardShape),

      // ✅ 抽屉整体圆角跟随全局 cardRadius
      drawerTheme: DrawerThemeData(shape: _drawerShape(cardRadius)),

      // ✅ 长条选择弹窗/底部弹层圆角统一
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),

      // ✅ Flutter 3.27+：DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkAlert,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkMenu,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
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