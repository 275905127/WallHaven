// (内容保持不变，直接覆盖以确保一致)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light(Color accentColor, {Color? customBg, Color? customCard}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // 如果 customBg 有值，强制使用，否则用默认 lightBackground
      scaffoldBackgroundColor: customBg ?? AppColors.lightBackground,
      cardColor: customCard ?? AppColors.lightCard,
      
      dialogBackgroundColor: AppColors.lightAlert,
      dividerColor: AppColors.lightDivider,
      
      colorScheme: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.light, primary: accentColor),
      dialogTheme: const DialogTheme(backgroundColor: AppColors.lightAlert, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)))),
      popupMenuTheme: const PopupMenuThemeData(color: AppColors.lightMenu, surfaceTintColor: Colors.transparent, textStyle: TextStyle(color: Colors.black, fontSize: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.black), titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600), systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark)),
      switchTheme: SwitchThemeData(thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : const Color(0xFF5D5D5D)), trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF0D0D0D) : const Color(0xFFE3E3E3)), trackOutlineColor: MaterialStateProperty.resolveWith((states) { if (states.contains(MaterialState.selected)) return Colors.transparent; return Colors.black.withOpacity(0.1); }), trackOutlineWidth: const MaterialStatePropertyAll(1.0)),
      textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black), bodyMedium: TextStyle(color: Color(0xFF8E8E93))),
    );
  }

  static ThemeData dark(Color accentColor, {Color? customBg, Color? customCard}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // 如果 customBg 有值，强制使用，否则用默认 darkBackground
      scaffoldBackgroundColor: customBg ?? AppColors.darkBackground,
      cardColor: customCard ?? AppColors.darkCard,
      
      dialogBackgroundColor: AppColors.darkAlert,
      dividerColor: AppColors.darkDivider,

      colorScheme: ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.dark, primary: accentColor),
      dialogTheme: const DialogTheme(backgroundColor: AppColors.darkAlert, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)))),
      popupMenuTheme: const PopupMenuThemeData(color: AppColors.darkMenu, surfaceTintColor: Colors.transparent, textStyle: TextStyle(color: Colors.white, fontSize: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.white), titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600), systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light)),
      switchTheme: SwitchThemeData(thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF0D0D0D) : const Color(0xFFC4C4C4)), trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFFFFFFFF) : const Color(0xFF3B3B3B)), trackOutlineColor: MaterialStateProperty.resolveWith((states) { if (states.contains(MaterialState.selected)) return Colors.transparent; return Colors.white.withOpacity(0.12); }), trackOutlineWidth: const MaterialStatePropertyAll(1.0)),
      textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white), bodyMedium: TextStyle(color: Color(0xFF9E9E9E))),
    );
  }
}
