// lib/widgets/foggy_app_bar.dart
import 'package:flutter/material.dart';

class FoggyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool isScrolled; // 控制是否显示雾化

  const FoggyAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.isScrolled,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76); // 保持 76 高度

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ 回归“主题驱动”：雾化底色跟随当前页面背景（支持自定义背景色）
    final baseColor = theme.scaffoldBackgroundColor;

    return AppBar(
      // ✅ 关键：禁止自动注入 Drawer 汉堡按钮（移除左上角筛选入口）
      automaticallyImplyLeading: false,

      title: title,
      centerTitle: true,

      // 仍允许你在需要的页面手动传 leading（比如设置页返回键）
      leading: leading,

      actions: actions,
      toolbarHeight: preferredSize.height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: AnimatedOpacity(
        opacity: isScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                baseColor.withOpacity(0.94),
                baseColor.withOpacity(0.94),
                baseColor.withOpacity(0.90),
                baseColor.withOpacity(0.75),
                baseColor.withOpacity(0.50),
                baseColor.withOpacity(0.20),
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