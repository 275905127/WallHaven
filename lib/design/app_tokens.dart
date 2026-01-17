import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // Switch
  final Color switchThumbOn;
  final Color switchThumbOff;
  final Color switchTrackOn;
  final Color switchTrackOff;
  final Color switchTrackOutline;
  final double switchTrackOutlineWidth;

  // Slider
  final Color sliderThumb;
  final Color sliderTrackActive;
  final Color sliderTrackInactive;

  // Other
  final Color chevronColor;
  final Color disabledFg;
  final Color dividerColor;

  // Size/shape
  final double smallRadius;
  final double dividerThickness;
  final double sliderTrackHeight;

  // =============================================================
  // FoggyAppBar (所有视觉常量必须在 tokens)
  // =============================================================

  /// 背景透明度：未滚动（更透明）
  final double appBarFogOpacityIdle; // 0..1

  /// 背景透明度：已滚动（更“实”）
  final double appBarFogOpacityScrolled; // 0..1

  /// 模糊：未滚动
  final double appBarBlurSigmaIdle;

  /// 模糊：已滚动
  final double appBarBlurSigmaScrolled;

  /// 下边线透明度（仅滚动时显示）
  final double appBarBottomStrokeOpacityScrolled; // 0..1

  /// 下边线宽度
  final double appBarBottomStrokeWidth;

  /// AppBar 水平内边距（Row 外层 padding）
  final double appBarHPadding;

  /// leading 左右间距（替代 SizedBox 6）
  final double appBarLeadingGap;

  /// actions 末尾间距（替代 SizedBox 6）
  final double appBarTrailingGap;

  // Motion
  final Duration expandDuration;
  final Curve expandCurve;

  // Legacy keep (避免旧引用炸)
  final Color controlThumb;
  final Color controlTrackActive;
  final Color controlTrackInactive;

  const AppTokens({
    required this.switchThumbOn,
    required this.switchThumbOff,
    required this.switchTrackOn,
    required this.switchTrackOff,
    required this.switchTrackOutline,
    required this.switchTrackOutlineWidth,
    required this.sliderThumb,
    required this.sliderTrackActive,
    required this.sliderTrackInactive,
    required this.chevronColor,
    required this.disabledFg,
    required this.dividerColor,
    required this.smallRadius,
    required this.dividerThickness,
    required this.sliderTrackHeight,

    // FoggyAppBar
    required this.appBarFogOpacityIdle,
    required this.appBarFogOpacityScrolled,
    required this.appBarBlurSigmaIdle,
    required this.appBarBlurSigmaScrolled,
    required this.appBarBottomStrokeOpacityScrolled,
    required this.appBarBottomStrokeWidth,
    required this.appBarHPadding,
    required this.appBarLeadingGap,
    required this.appBarTrailingGap,

    required this.expandDuration,
    required this.expandCurve,
    required this.controlThumb,
    required this.controlTrackActive,
    required this.controlTrackInactive,
  });

  static AppTokens light() {
    return AppTokens(
      // Switch (light)
      switchThumbOn: const Color(0xFFFFFFFF),
      switchThumbOff: const Color(0xFF5D5D5D),
      switchTrackOn: const Color(0xFF0D0D0D),
      switchTrackOff: const Color(0xFFE3E3E3),
      switchTrackOutline: Colors.black.withAlpha(26), // ~10%
      switchTrackOutlineWidth: 1.0,

      // Slider (light)
      sliderThumb: const Color(0xFFFFFFFF),
      sliderTrackActive: const Color(0xFF0D0D0D),
      sliderTrackInactive: const Color(0xFFE3E3E3),

      chevronColor: const Color(0xFFC7C7CC),
      disabledFg: Colors.black54,
      dividerColor: const Color(0xFFFFFFFF),

      smallRadius: 4.0,
      dividerThickness: 2.0,
      sliderTrackHeight: 5.0,

      // FoggyAppBar (light)
      appBarFogOpacityIdle: 0.20,
      appBarFogOpacityScrolled: 0.82,
      appBarBlurSigmaIdle: 10.8, // 18 * 0.6
      appBarBlurSigmaScrolled: 18.0,
      appBarBottomStrokeOpacityScrolled: 0.10,
      appBarBottomStrokeWidth: 1.0,
      appBarHPadding: 0.0,
      appBarLeadingGap: 6.0,
      appBarTrailingGap: 6.0,

      expandDuration: const Duration(milliseconds: 220),
      expandCurve: Curves.easeInOut,

      // legacy
      controlThumb: const Color(0xFFFFFFFF),
      controlTrackActive: const Color(0xFF0D0D0D),
      controlTrackInactive: const Color(0xFFE3E3E3),
    );
  }

  static AppTokens dark() {
    return AppTokens(
      // Switch (dark)
      switchThumbOn: const Color(0xFF0D0D0D),
      switchThumbOff: const Color(0xFFC4C4C4),
      switchTrackOn: const Color(0xFFFFFFFF),
      switchTrackOff: const Color(0xFF3B3B3B),
      switchTrackOutline: Colors.white.withAlpha(31), // ~12%
      switchTrackOutlineWidth: 1.0,

      // Slider (dark)
      sliderThumb: const Color(0xFF0D0D0D),
      sliderTrackActive: const Color(0xFFFFFFFF),
      sliderTrackInactive: const Color(0xFF3B3B3B),

      chevronColor: const Color(0xFF666666),
      disabledFg: Colors.white54,
      dividerColor: const Color(0xFF000000),

      smallRadius: 4.0,
      dividerThickness: 2.0,
      sliderTrackHeight: 5.0,

      // FoggyAppBar (dark)
      appBarFogOpacityIdle: 0.20,
      appBarFogOpacityScrolled: 0.78,
      appBarBlurSigmaIdle: 10.8,
      appBarBlurSigmaScrolled: 18.0,
      appBarBottomStrokeOpacityScrolled: 0.14,
      appBarBottomStrokeWidth: 1.0,
      appBarHPadding: 0.0,
      appBarLeadingGap: 6.0,
      appBarTrailingGap: 6.0,

      expandDuration: const Duration(milliseconds: 220),
      expandCurve: Curves.easeInOut,

      // legacy
      controlThumb: const Color(0xFFFFFFFF),
      controlTrackActive: const Color(0xFF0D0D0D),
      controlTrackInactive: const Color(0xFF3B3B3B),
    );
  }

  @override
  AppTokens copyWith({
    Color? switchThumbOn,
    Color? switchThumbOff,
    Color? switchTrackOn,
    Color? switchTrackOff,
    Color? switchTrackOutline,
    double? switchTrackOutlineWidth,
    Color? sliderThumb,
    Color? sliderTrackActive,
    Color? sliderTrackInactive,
    Color? chevronColor,
    Color? disabledFg,
    Color? dividerColor,
    double? smallRadius,
    double? dividerThickness,
    double? sliderTrackHeight,

    // FoggyAppBar
    double? appBarFogOpacityIdle,
    double? appBarFogOpacityScrolled,
    double? appBarBlurSigmaIdle,
    double? appBarBlurSigmaScrolled,
    double? appBarBottomStrokeOpacityScrolled,
    double? appBarBottomStrokeWidth,
    double? appBarHPadding,
    double? appBarLeadingGap,
    double? appBarTrailingGap,

    Duration? expandDuration,
    Curve? expandCurve,
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

      appBarFogOpacityIdle: appBarFogOpacityIdle ?? this.appBarFogOpacityIdle,
      appBarFogOpacityScrolled: appBarFogOpacityScrolled ?? this.appBarFogOpacityScrolled,
      appBarBlurSigmaIdle: appBarBlurSigmaIdle ?? this.appBarBlurSigmaIdle,
      appBarBlurSigmaScrolled: appBarBlurSigmaScrolled ?? this.appBarBlurSigmaScrolled,
      appBarBottomStrokeOpacityScrolled:
          appBarBottomStrokeOpacityScrolled ?? this.appBarBottomStrokeOpacityScrolled,
      appBarBottomStrokeWidth: appBarBottomStrokeWidth ?? this.appBarBottomStrokeWidth,
      appBarHPadding: appBarHPadding ?? this.appBarHPadding,
      appBarLeadingGap: appBarLeadingGap ?? this.appBarLeadingGap,
      appBarTrailingGap: appBarTrailingGap ?? this.appBarTrailingGap,

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
      switchThumbOn: Color.lerp(switchThumbOn, other.switchThumbOn, t) ?? switchThumbOn,
      switchThumbOff: Color.lerp(switchThumbOff, other.switchThumbOff, t) ?? switchThumbOff,
      switchTrackOn: Color.lerp(switchTrackOn, other.switchTrackOn, t) ?? switchTrackOn,
      switchTrackOff: Color.lerp(switchTrackOff, other.switchTrackOff, t) ?? switchTrackOff,
      switchTrackOutline:
          Color.lerp(switchTrackOutline, other.switchTrackOutline, t) ?? switchTrackOutline,
      switchTrackOutlineWidth:
          lerpDouble(switchTrackOutlineWidth, other.switchTrackOutlineWidth, t) ??
              switchTrackOutlineWidth,

      sliderThumb: Color.lerp(sliderThumb, other.sliderThumb, t) ?? sliderThumb,
      sliderTrackActive:
          Color.lerp(sliderTrackActive, other.sliderTrackActive, t) ?? sliderTrackActive,
      sliderTrackInactive:
          Color.lerp(sliderTrackInactive, other.sliderTrackInactive, t) ?? sliderTrackInactive,

      chevronColor: Color.lerp(chevronColor, other.chevronColor, t) ?? chevronColor,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t) ?? disabledFg,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor,

      smallRadius: lerpDouble(smallRadius, other.smallRadius, t) ?? smallRadius,
      dividerThickness: lerpDouble(dividerThickness, other.dividerThickness, t) ?? dividerThickness,
      sliderTrackHeight: lerpDouble(sliderTrackHeight, other.sliderTrackHeight, t) ?? sliderTrackHeight,

      appBarFogOpacityIdle:
          lerpDouble(appBarFogOpacityIdle, other.appBarFogOpacityIdle, t) ?? appBarFogOpacityIdle,
      appBarFogOpacityScrolled:
          lerpDouble(appBarFogOpacityScrolled, other.appBarFogOpacityScrolled, t) ??
              appBarFogOpacityScrolled,
      appBarBlurSigmaIdle:
          lerpDouble(appBarBlurSigmaIdle, other.appBarBlurSigmaIdle, t) ?? appBarBlurSigmaIdle,
      appBarBlurSigmaScrolled:
          lerpDouble(appBarBlurSigmaScrolled, other.appBarBlurSigmaScrolled, t) ??
              appBarBlurSigmaScrolled,
      appBarBottomStrokeOpacityScrolled:
          lerpDouble(appBarBottomStrokeOpacityScrolled, other.appBarBottomStrokeOpacityScrolled, t) ??
              appBarBottomStrokeOpacityScrolled,
      appBarBottomStrokeWidth:
          lerpDouble(appBarBottomStrokeWidth, other.appBarBottomStrokeWidth, t) ??
              appBarBottomStrokeWidth,
      appBarHPadding: lerpDouble(appBarHPadding, other.appBarHPadding, t) ?? appBarHPadding,
      appBarLeadingGap: lerpDouble(appBarLeadingGap, other.appBarLeadingGap, t) ?? appBarLeadingGap,
      appBarTrailingGap:
          lerpDouble(appBarTrailingGap, other.appBarTrailingGap, t) ?? appBarTrailingGap,

      expandDuration: other.expandDuration,
      expandCurve: other.expandCurve,

      controlThumb: Color.lerp(controlThumb, other.controlThumb, t) ?? controlThumb,
      controlTrackActive:
          Color.lerp(controlTrackActive, other.controlTrackActive, t) ?? controlTrackActive,
      controlTrackInactive:
          Color.lerp(controlTrackInactive, other.controlTrackInactive, t) ?? controlTrackInactive,
    );
  }
}