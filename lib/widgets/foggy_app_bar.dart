// lib/widgets/foggy_app_bar.dart
import 'package:flutter/material.dart';

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

  const FoggyAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.isScrolled,
    this.fogStrength = 1.0,
    this.fogDuration = const Duration(milliseconds: 200),
    this.fogCurve = Curves.easeInOut,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76); // 保持 76 高度

  double _o(double v) {
    final s = fogStrength.clamp(0.0, 1.0);
    return (v * s).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ 主题驱动：雾化底色跟随当前页面背景（支持自定义背景色）
    final baseColor = theme.scaffoldBackgroundColor;

    return AppBar(
      // ✅ 禁止自动注入 Drawer 汉堡按钮（移除左上角筛选入口）
      automaticallyImplyLeading: false,

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