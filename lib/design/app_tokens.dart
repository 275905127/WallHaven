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

  // FoggyAppBar (把雾化也收口进 tokens，别让它在组件里硬编码)
  final double appBarBlurSigma;
  final double appBarFogOpacity; // 0..1
  final double appBarBottomStrokeOpacity; // 0..1

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
    required this.appBarBlurSigma,
    required this.appBarFogOpacity,
    required this.appBarBottomStrokeOpacity,
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

      // FoggyAppBar
      appBarBlurSigma: 18.0,
      appBarFogOpacity: 0.72,
      appBarBottomStrokeOpacity: 0.10,

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

      // FoggyAppBar
      appBarBlurSigma: 18.0,
      appBarFogOpacity: 0.62,
      appBarBottomStrokeOpacity: 0.14,

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
    double? appBarBlurSigma,
    double? appBarFogOpacity,
    double? appBarBottomStrokeOpacity,
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
      appBarBlurSigma: appBarBlurSigma ?? this.appBarBlurSigma,
      appBarFogOpacity: appBarFogOpacity ?? this.appBarFogOpacity,
      appBarBottomStrokeOpacity: appBarBottomStrokeOpacity ?? this.appBarBottomStrokeOpacity,
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
      switchTrackOutline: Color.lerp(switchTrackOutline, other.switchTrackOutline, t) ?? switchTrackOutline,
      switchTrackOutlineWidth:
          lerpDouble(switchTrackOutlineWidth, other.switchTrackOutlineWidth, t) ?? switchTrackOutlineWidth,

      sliderThumb: Color.lerp(sliderThumb, other.sliderThumb, t) ?? sliderThumb,
      sliderTrackActive: Color.lerp(sliderTrackActive, other.sliderTrackActive, t) ?? sliderTrackActive,
      sliderTrackInactive: Color.lerp(sliderTrackInactive, other.sliderTrackInactive, t) ?? sliderTrackInactive,

      chevronColor: Color.lerp(chevronColor, other.chevronColor, t) ?? chevronColor,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t) ?? disabledFg,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor,

      smallRadius: lerpDouble(smallRadius, other.smallRadius, t) ?? smallRadius,
      dividerThickness: lerpDouble(dividerThickness, other.dividerThickness, t) ?? dividerThickness,
      sliderTrackHeight: lerpDouble(sliderTrackHeight, other.sliderTrackHeight, t) ?? sliderTrackHeight,

      appBarBlurSigma: lerpDouble(appBarBlurSigma, other.appBarBlurSigma, t) ?? appBarBlurSigma,
      appBarFogOpacity: lerpDouble(appBarFogOpacity, other.appBarFogOpacity, t) ?? appBarFogOpacity,
      appBarBottomStrokeOpacity:
          lerpDouble(appBarBottomStrokeOpacity, other.appBarBottomStrokeOpacity, t) ?? appBarBottomStrokeOpacity,

      expandDuration: other.expandDuration,
      expandCurve: other.expandCurve,

      controlThumb: Color.lerp(controlThumb, other.controlThumb, t) ?? controlThumb,
      controlTrackActive: Color.lerp(controlTrackActive, other.controlTrackActive, t) ?? controlTrackActive,
      controlTrackInactive: Color.lerp(controlTrackInactive, other.controlTrackInactive, t) ?? controlTrackInactive,
    );
  }
}