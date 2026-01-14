import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  // ☀️ 浅色主题 (新增 cardRadius 参数)
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

      // 🌟 修改：使用传入的 cardRadius，且移除 const
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightAlert,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRadius))),
      ),
      
      // 🌟 修改：弹出菜单也同步圆角
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
      
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : const Color(0xFF5D5D5D)),
        trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF0D0D0D) : const Color(0xFFE3E3E3)),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.transparent;
          return Colors.black.withOpacity(0.1);
        }),
        trackOutlineWidth: const MaterialStatePropertyAll(1.0),
      ),
      
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Color(0xFF8E8E93)),
      ),
    );
  }

  // 🌙 深色主题 (新增 cardRadius 参数)
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
      
      // 🌟 修改：使用传入的 cardRadius，且移除 const
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkAlert,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(cardRadius))),
      ),

      // 🌟 修改：弹出菜单也同步圆角
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
      
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF0D0D0D) : const Color(0xFFC4C4C4)),
        trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFFFFFFFF) : const Color(0xFF3B3B3B)),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.transparent;
          return Colors.white.withOpacity(0.12);
        }),
        trackOutlineWidth: const MaterialStatePropertyAll(1.0),
      ),
      
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFF9E9E9E)),
      ),
    );
  }
}
