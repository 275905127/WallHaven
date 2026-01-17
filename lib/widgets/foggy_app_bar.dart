import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class FoggyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final bool isScrolled;
  final double fogStrength;
  final Widget? leading;
  final List<Widget> actions;

  const FoggyAppBar({
    super.key,
    required this.title,
    required this.isScrolled,
    this.fogStrength = 0.82,
    this.leading,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 轻微分隔线（保留“雾化+边界”语义；具体视觉你后面再用 tokens 收敛）
    final borderColor = theme.dividerColor.withOpacity(isScrolled ? 0.35 : 0.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: isScrolled ? 18 : 0,
          sigmaY: isScrolled ? 18 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(isScrolled ? fogStrength : 0.0),
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  leading ??
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: Scaffold.maybeOf(context)?.openDrawer,
                        tooltip: 'Menu',
                      ),
                  Expanded(
                    child: DefaultTextStyle(
                      style: theme.appBarTheme.titleTextStyle ??
                          theme.textTheme.titleMedium ??
                          const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: title,
                    ),
                  ),
                  ...actions,
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}