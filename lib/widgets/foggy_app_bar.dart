import 'package:flutter/material.dart';

class FoggyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool isScrolled; // 核心控制参数

  const FoggyAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.isScrolled,
  });

  // ⚠️ 严格保留原代码高度参数
  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 动态获取当前主题背景色（黑/白）
    final baseColor = isDark ? Colors.black : Colors.white;

    return AppBar(
      title: title,
      centerTitle: true,
      leading: leading,
      actions: actions,
      toolbarHeight: preferredSize.height, // 96
      
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      
      // ⚠️ 严格保留原代码的 6 段式渐变参数
      flexibleSpace: isScrolled 
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // [1]
                    baseColor.withOpacity(0.94),
                    // [2]
                    baseColor.withOpacity(0.94),
                    // [3]
                    baseColor.withOpacity(0.90),
                    // [4]
                    baseColor.withOpacity(0.75),
                    // [5]
                    baseColor.withOpacity(0.50),
                    // [6]
                    baseColor.withOpacity(0.20),
                    // [7]
                    baseColor.withOpacity(0.0),
                  ],
                  // 6段式精密节点
                  stops: const [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], 
                ),
              ),
            )
          : null,
    );
  }
}
