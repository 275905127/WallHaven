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
  Size get preferredSize => const Size.fromHeight(96); // 保持 96 高度

  @override
  Widget build(BuildContext context) {
    // 动态获取颜色
    final baseColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.black 
        : Colors.white;

    return AppBar(
      title: title,
      centerTitle: true,
      leading: leading,
      actions: actions,
      toolbarHeight: preferredSize.height,
      
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      
      // 🌟 核心：使用 AnimatedOpacity 实现呼吸渐变
      // 注意：这里不需要三元运算符 (? :) 的 else 分支
      flexibleSpace: AnimatedOpacity(
        opacity: isScrolled ? 1.0 : 0.0, // 有滚动显示 1.0，无滚动隐藏 0.0
        duration: const Duration(milliseconds: 200), // 呼吸时长
        curve: Curves.easeInOut, // 柔和曲线
        
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
