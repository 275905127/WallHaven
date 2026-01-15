// lib/widgets/foggy_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FoggyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;

  /// 控制是否显示雾化（滚动后显示）
  final bool isScrolled;

  /// ✅ 雾化强度（用于主页/设置页分别控制）
  /// 1.0 = 当前默认强度；0.0 = 不雾化；建议主页用 0.75~0.9 更淡
  final double fogStrength;

  /// ✅ 雾化动画时长
  final Duration fogDuration;

  /// ✅ 雾化动画曲线
  final Curve fogCurve;

  /// ✅ 系统状态栏/导航栏是否由 FoggyAppBar 显式接管
  /// 目的：不让 Theme.appBarTheme.systemOverlayStyle 抢回去导致抽屉页不同步
  final bool manageSystemOverlay;

  /// ✅ 当抽屉打开（或你希望“强制同步背景”）时打开
  /// 打开后：状态栏/导航栏颜色 = scaffoldBackgroundColor（不透明），确保和筛选页背景一致
  final bool forceOverlayMatchBackground;

  const FoggyAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.isScrolled,
    this.fogStrength = 1.0,
    this.fogDuration = const Duration(milliseconds: 200),
    this.fogCurve = Curves.easeInOut,
    this.manageSystemOverlay = true,
    this.forceOverlayMatchBackground = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76); // 保持 76 高度

  double _o(double v) {
    final s = fogStrength.clamp(0.0, 1.0);
    return (v * s).clamp(0.0, 1.0);
  }

  SystemUiOverlayStyle _overlayStyle(BuildContext context, Color baseColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ 抽屉打开 / 强制同步背景：用纯背景色（不透明），避免任何透明导致“看起来不一致”
    if (forceOverlayMatchBackground) {
      return SystemUiOverlayStyle(
        statusBarColor: baseColor,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light, // iOS
        systemNavigationBarColor: baseColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      );
    }

    // ✅ 常规：未滚动 → 透明；滚动后 → 轻雾化（颜色来自页面背景）
    final Color barColor = isScrolled
        ? baseColor.withOpacity(_o(0.94))
        : Colors.transparent;

    return SystemUiOverlayStyle(
      statusBarColor: barColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light, // iOS
      systemNavigationBarColor: barColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ 主题驱动：雾化底色跟随当前页面背景（支持自定义背景色）
    final baseColor = theme.scaffoldBackgroundColor;

    return AppBar(
      // ✅ 禁止自动注入 Drawer 汉堡按钮（移除左上角筛选入口）
      automaticallyImplyLeading: false,

      // ✅ 关键：显式接管 overlay，避免 Theme 抢回去
      systemOverlayStyle: manageSystemOverlay ? _overlayStyle(context, baseColor) : null,

      title: title,
      centerTitle: true,

      // 仍允许手动传 leading（比如设置页返回键）
      leading: leading,

      actions: actions,
      toolbarHeight: preferredSize.height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: AnimatedOpacity(
        opacity: isScrolled ? 1.0 : 0.0,
        duration: fogDuration,
        curve: fogCurve,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                baseColor.withOpacity(_o(0.94)),
                baseColor.withOpacity(_o(0.94)),
                baseColor.withOpacity(_o(0.90)),
                baseColor.withOpacity(_o(0.75)),
                baseColor.withOpacity(_o(0.50)),
                baseColor.withOpacity(_o(0.20)),
                baseColor.withOpacity(0.0),
              ],
              stops: const [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}