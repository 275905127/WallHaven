// lib/theme/app_colors.dart
// =============================================================
// ⚠️ DESIGN GUARD — 绝对禁止私自改动 ⚠️
//
// 这里只允许存放“基础颜色常量”。
// 视觉语义 / 圆角 / 分割 / 动画等全部由 AppTokens 统一管理。
//
// ❌ 禁止在这里写 AppTokens / ThemeExtension / 任何组件逻辑
// ✅ 这里只做颜色常量的唯一出口
// =============================================================

import 'package:flutter/material.dart';

class AppColors {
  // Light
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF3F3F3);
  static const Color lightAlert = Color(0xFFE5E5E5);
  static const Color lightMenu = Color(0xFFEBEBEB);

  // ⚠️ dividerColor 这里只兜底；真正的 2px 背景缝走 tokens.dividerColor
  static const Color lightDivider = Color(0xFFFFFFFF);

  // Dark
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF414141);
  static const Color darkAlert = Color(0xFF1B1B1B);
  static const Color darkMenu = Color(0xFF333333);

  // ⚠️ dividerColor 这里只兜底；真正的 2px 背景缝走 tokens.dividerColor
  static const Color darkDivider = Color(0xFF000000);

  // Brand
  static const Color brandYellow = Color(0xFFD2AE00);
}