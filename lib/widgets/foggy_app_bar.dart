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
      
      // 🌟 优化点：使用 AnimatedOpacity 实现呼吸渐变
      flexibleSpace: AnimatedOpacity(
        // 只要 isScrolled 变了，它自动会在 200ms 内做淡入淡出
        opacity: isScrolled ? 1.0 : 0.0, 
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut, // 缓动曲线
        
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                 // ... 你的 6 段式颜色 (保持不变)
                 baseColor.withOpacity(0.94),
                 baseColor.withOpacity(0.94),
                 baseColor.withOpacity(0.90),
                 baseColor.withOpacity(0.75),
                 baseColor.withOpacity(0.50),
                 baseColor.withOpacity(0.20),
                 baseColor.withOpacity(0.0),
              ],
                  // 6段式精密节点
                  stops: const [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], 
                ),
             ),
          ),
       ),
    );
  }
}
