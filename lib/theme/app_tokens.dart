// lib/theme/app_tokens.dart
import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // 语义颜色（页面只拿语义，不写具体色）
  final Color controlThumb; // Switch/Slider 圆点
  final Color controlTrackActive; // Switch 选中轨道 & Slider 轨道
  final Color controlTrackInactive; // Switch 未选中轨道

  final Color chevronColor; // SettingsGroup 右侧箭头
  final Color disabledFg; // 禁用文字/图标
  final Color dividerColor; // 分隔线颜色（你用 Container 的 2px）

  // 尺寸/形状
  final double smallRadius; // 连接处小圆角
  final double dividerThickness;
  final double sliderTrackHeight;

  // 动画
  final Duration expandDuration;
  final Curve expandCurve;

  const AppTokens({
    required this.controlThumb,
    required this.controlTrackActive,
    required this.controlTrackInactive,
    required this.chevronColor,
    required this.disabledFg,
    required this.dividerColor,
    required this.smallRadius,
    required this.dividerThickness,
    required this.sliderTrackHeight,
    required this.expandDuration,
    required this.expandCurve,
  });

  static AppTokens light() {
    const blackTrack = Color(0xFF0D0D0D); // 你说的“自定义颜色开关同款黑”
    return AppTokens(
      controlThumb: Colors.white,
      controlTrackActive: blackTrack,
      controlTrackInactive: const Color(0xFFE3E3E3),
      chevronColor: const Color(0xFFC7C7CC),
      disabledFg: Colors.black54,
      dividerColor: Colors.white,
      smallRadius: 4.0,
      dividerThickness: 2.0,
      sliderTrackHeight: 5.0, // 稍微加粗
      expandDuration: const Duration(milliseconds: 220),
      expandCurve: Curves.easeInOut,
    );
    }

  static AppTokens dark() {
    const blackTrack = Color(0xFF0D0D0D);
    return AppTokens(
      controlThumb: Colors.white,
      controlTrackActive: blackTrack,
      controlTrackInactive: const Color(0xFF3B3B3B),
      chevronColor: const Color(0xFF666666),
      disabledFg: Colors.white54,
      dividerColor: Colors.black,
      smallRadius: 4.0,
      dividerThickness: 2.0,
      sliderTrackHeight: 5.0,
      expandDuration: const Duration(milliseconds: 220),
      expandCurve: Curves.easeInOut,
    );
  }

  @override
  AppTokens copyWith({
    Color? controlThumb,
    Color? controlTrackActive,
    Color? controlTrackInactive,
    Color? chevronColor,
    Color? disabledFg,
    Color? dividerColor,
    double? smallRadius,
    double? dividerThickness,
    double? sliderTrackHeight,
    Duration? expandDuration,
    Curve? expandCurve,
  }) {
    return AppTokens(
      controlThumb: controlThumb ?? this.controlThumb,
      controlTrackActive: controlTrackActive ?? this.controlTrackActive,
      controlTrackInactive: controlTrackInactive ?? this.controlTrackInactive,
      chevronColor: chevronColor ?? this.chevronColor,
      disabledFg: disabledFg ?? this.disabledFg,
      dividerColor: dividerColor ?? this.dividerColor,
      smallRadius: smallRadius ?? this.smallRadius,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      sliderTrackHeight: sliderTrackHeight ?? this.sliderTrackHeight,
      expandDuration: expandDuration ?? this.expandDuration,
      expandCurve: expandCurve ?? this.expandCurve,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      controlThumb: Color.lerp(controlThumb, other.controlThumb, t) ?? controlThumb,
      controlTrackActive: Color.lerp(controlTrackActive, other.controlTrackActive, t) ?? controlTrackActive,
      controlTrackInactive: Color.lerp(controlTrackInactive, other.controlTrackInactive, t) ?? controlTrackInactive,
      chevronColor: Color.lerp(chevronColor, other.chevronColor, t) ?? chevronColor,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t) ?? disabledFg,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor,
      smallRadius: lerpDouble(smallRadius, other.smallRadius, t) ?? smallRadius,
      dividerThickness: lerpDouble(dividerThickness, other.dividerThickness, t) ?? dividerThickness,
      sliderTrackHeight: lerpDouble(sliderTrackHeight, other.sliderTrackHeight, t) ?? sliderTrackHeight,
      expandDuration: other.expandDuration,
      expandCurve: other.expandCurve,
    );
  }
}
