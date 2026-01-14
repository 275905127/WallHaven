// lib/theme/app_tokens.dart
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // =========================
  // Switch 语义色（按你规范）
  // =========================
  final Color switchThumbOn;
  final Color switchThumbOff;
  final Color switchTrackOn;
  final Color switchTrackOff;

  // Switch 轨道描边
  final Color switchTrackOutline;
  final double switchTrackOutlineWidth;

  // =========================
  // Slider 语义色（按你规范）
  // =========================
  final Color sliderThumb;
  final Color sliderTrackActive;
  final Color sliderTrackInactive;

  // =========================
  // 其它语义色
  // =========================
  final Color chevronColor; // SettingsGroup 右侧箭头
  final Color disabledFg; // 禁用文字/图标
  final Color dividerColor; // 分隔线颜色（2px 背景缝）

  // =========================
  // 尺寸/形状
  // =========================
  final double smallRadius; // 连接处小圆角
  final double dividerThickness;
  final double sliderTrackHeight;

  // 动画
  final Duration expandDuration;
  final Curve expandCurve;

  // =========================
  // 兼容字段（不再作为规范来源）
  // 仅用于避免旧代码引用报错
  // =========================
  final Color controlThumb; // 旧：Switch/Slider 圆点
  final Color controlTrackActive; // 旧：Switch 选中轨道 & Slider 轨道
  final Color controlTrackInactive; // 旧：Switch 未选中轨道

  const AppTokens({
    // Switch
    required this.switchThumbOn,
    required this.switchThumbOff,
    required this.switchTrackOn,
    required this.switchTrackOff,
    required this.switchTrackOutline,
    required this.switchTrackOutlineWidth,

    // Slider
    required this.sliderThumb,
    required this.sliderTrackActive,
    required this.sliderTrackInactive,

    // Other
    required this.chevronColor,
    required this.disabledFg,
    required this.dividerColor,

    // Size
    required this.smallRadius,
    required this.dividerThickness,
    required this.sliderTrackHeight,

    // Motion
    required this.expandDuration,
    required this.expandCurve,

    // Legacy (keep)
    required this.controlThumb,
    required this.controlTrackActive,
    required this.controlTrackInactive,
  });

  static AppTokens light() {
    return AppTokens(
      // ✅ Switch（浅色）
      // OFF：thumb 5D5D5D / track E3E3E3
      // ON ：thumb FFFFFF / track 0D0D0D
      switchThumbOn: const Color(0xFFFFFFFF),
      switchThumbOff: const Color(0xFF5D5D5D),
      switchTrackOn: const Color(0xFF0D0D0D),
      switchTrackOff: const Color(0xFFE3E3E3),

      // 轨道描边（浅色）
      switchTrackOutline: Colors.black.withOpacity(0.10),
      switchTrackOutlineWidth: 1.0,

      // ✅ Slider（浅色）
      // active 0D0D0D / inactive E3E3E3 / thumb FFFFFF
      sliderThumb: const Color(0xFFFFFFFF),
      sliderTrackActive: const Color(0xFF0D0D0D),
      sliderTrackInactive: const Color(0xFFE3E3E3),

      chevronColor: const Color(0xFFC7C7CC),
      disabledFg: Colors.black54,
      dividerColor: const Color(0xFFFFFFFF),

      smallRadius: 4.0,
      dividerThickness: 2.0,
      sliderTrackHeight: 5.0,

      expandDuration: const Duration(milliseconds: 220),
      expandCurve: Curves.easeInOut,

      // legacy（保持不报错）
      controlThumb: const Color(0xFFFFFFFF),
      controlTrackActive: const Color(0xFF0D0D0D),
      controlTrackInactive: const Color(0xFFE3E3E3),
    );
  }

  static AppTokens dark() {
    return AppTokens(
      // ✅ Switch（深色）
      // OFF：thumb C4C4C4 / track 3B3B3B
      // ON ：thumb 0D0D0D / track FFFFFF
      switchThumbOn: const Color(0xFF0D0D0D),
      switchThumbOff: const Color(0xFFC4C4C4),
      switchTrackOn: const Color(0xFFFFFFFF),
      switchTrackOff: const Color(0xFF3B3B3B),

      // 轨道描边（深色）
      switchTrackOutline: Colors.white.withOpacity(0.12),
      switchTrackOutlineWidth: 1.0,

      // ✅ Slider（深色）
      // active FFFFFF / inactive 3B3B3B / thumb 0D0D0D
      sliderThumb: const Color(0xFF0D0D0D),
      sliderTrackActive: const Color(0xFFFFFFFF),
      sliderTrackInactive: const Color(0xFF3B3B3B),

      chevronColor: const Color(0xFF666666),
      disabledFg: Colors.white54,
      dividerColor: const Color(0xFF000000),

      smallRadius: 4.0,
      dividerThickness: 2.0,
      sliderTrackHeight: 5.0,

      expandDuration: const Duration(milliseconds: 220),
      expandCurve: Curves.easeInOut,

      // legacy（保持不报错）
      controlThumb: const Color(0xFFFFFFFF),
      controlTrackActive: const Color(0xFF0D0D0D),
      controlTrackInactive: const Color(0xFF3B3B3B),
    );
  }

  @override
  AppTokens copyWith({
    // Switch
    Color? switchThumbOn,
    Color? switchThumbOff,
    Color? switchTrackOn,
    Color? switchTrackOff,
    Color? switchTrackOutline,
    double? switchTrackOutlineWidth,

    // Slider
    Color? sliderThumb,
    Color? sliderTrackActive,
    Color? sliderTrackInactive,

    // Other
    Color? chevronColor,
    Color? disabledFg,
    Color? dividerColor,

    // Size
    double? smallRadius,
    double? dividerThickness,
    double? sliderTrackHeight,

    // Motion
    Duration? expandDuration,
    Curve? expandCurve,

    // Legacy
    Color? controlThumb,
    Color? controlTrackActive,
    Color? controlTrackInactive,
  }) {
    return AppTokens(
      switchThumbOn: switchThumbOn ?? this.switchThumbOn,
      switchThumbOff: switchThumbOff ?? this.switchThumbOff,
      switchTrackOn: switchTrackOn ?? this.switchTrackOn,
      switchTrackOff: switchTrackOff ?? this.switchTrackOff,
      switchTrackOutline: switchTrackOutline ?? this.switchTrackOutline,
      switchTrackOutlineWidth: switchTrackOutlineWidth ?? this.switchTrackOutlineWidth,

      sliderThumb: sliderThumb ?? this.sliderThumb,
      sliderTrackActive: sliderTrackActive ?? this.sliderTrackActive,
      sliderTrackInactive: sliderTrackInactive ?? this.sliderTrackInactive,

      chevronColor: chevronColor ?? this.chevronColor,
      disabledFg: disabledFg ?? this.disabledFg,
      dividerColor: dividerColor ?? this.dividerColor,

      smallRadius: smallRadius ?? this.smallRadius,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      sliderTrackHeight: sliderTrackHeight ?? this.sliderTrackHeight,

      expandDuration: expandDuration ?? this.expandDuration,
      expandCurve: expandCurve ?? this.expandCurve,

      controlThumb: controlThumb ?? this.controlThumb,
      controlTrackActive: controlTrackActive ?? this.controlTrackActive,
      controlTrackInactive: controlTrackInactive ?? this.controlTrackInactive,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      // Switch
      switchThumbOn: Color.lerp(switchThumbOn, other.switchThumbOn, t) ?? switchThumbOn,
      switchThumbOff: Color.lerp(switchThumbOff, other.switchThumbOff, t) ?? switchThumbOff,
      switchTrackOn: Color.lerp(switchTrackOn, other.switchTrackOn, t) ?? switchTrackOn,
      switchTrackOff: Color.lerp(switchTrackOff, other.switchTrackOff, t) ?? switchTrackOff,
      switchTrackOutline: Color.lerp(switchTrackOutline, other.switchTrackOutline, t) ?? switchTrackOutline,
      switchTrackOutlineWidth: lerpDouble(switchTrackOutlineWidth, other.switchTrackOutlineWidth, t) ?? switchTrackOutlineWidth,

      // Slider
      sliderThumb: Color.lerp(sliderThumb, other.sliderThumb, t) ?? sliderThumb,
      sliderTrackActive: Color.lerp(sliderTrackActive, other.sliderTrackActive, t) ?? sliderTrackActive,
      sliderTrackInactive: Color.lerp(sliderTrackInactive, other.sliderTrackInactive, t) ?? sliderTrackInactive,

      // Other
      chevronColor: Color.lerp(chevronColor, other.chevronColor, t) ?? chevronColor,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t) ?? disabledFg,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor,

      // Size
      smallRadius: lerpDouble(smallRadius, other.smallRadius, t) ?? smallRadius,
      dividerThickness: lerpDouble(dividerThickness, other.dividerThickness, t) ?? dividerThickness,
      sliderTrackHeight: lerpDouble(sliderTrackHeight, other.sliderTrackHeight, t) ?? sliderTrackHeight,

      // Motion
      expandDuration: other.expandDuration,
      expandCurve: other.expandCurve,

      // Legacy
      controlThumb: Color.lerp(controlThumb, other.controlThumb, t) ?? controlThumb,
      controlTrackActive: Color.lerp(controlTrackActive, other.controlTrackActive, t) ?? controlTrackActive,
      controlTrackInactive: Color.lerp(controlTrackInactive, other.controlTrackInactive, t) ?? controlTrackInactive,
    );
  }
}