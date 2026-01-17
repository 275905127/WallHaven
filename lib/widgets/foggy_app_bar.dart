import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class FoggyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final bool isScrolled;

  /// 允许外部完全接管 leading（比如返回按钮）
  final Widget? leading;

  /// 右侧 actions
  final List<Widget> actions;

  /// 是否自动给一个“菜单按钮”（仅当 Scaffold 有 drawer 且 leading 为空时）
  final bool autoImplyDrawer;

  /// 雾化强度（0~1），越大越“实”
  final double fogStrength;

  /// 模糊半径
  final double blurSigma;

  /// 可选：下边框强度（0~1），为 0 就不画
  final double dividerStrength;

  const FoggyAppBar({
    super.key,
    required this.title,
    required this.isScrolled,
    this.leading,
    this.actions = const [],
    this.autoImplyDrawer = true,
    this.fogStrength = 0.82,
    this.blurSigma = 18,
    this.dividerStrength = 0.12,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (!autoImplyDrawer) return null;

    final scaffold = Scaffold.maybeOf(context);
    final hasDrawer = scaffold?.hasDrawer ?? false;
    if (!hasDrawer) return null;

    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: scaffold?.openDrawer,
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 背景：不滚动时更透明；滚动后更“实”
    final double t = isScrolled ? 1.0 : 0.0;
    final double opacity = (0.20 + (fogStrength - 0.20) * t).clamp(0.0, 1.0);

    final Color bg = theme.scaffoldBackgroundColor.withOpacity(opacity);

    // 下边框：只在滚动时出现（避免视觉脏）
    final bool showDivider = dividerStrength > 0 && isScrolled;
    final Color divider = theme.dividerColor.withOpacity(dividerStrength.clamp(0.0, 1.0));

    final leadingWidget = _buildLeading(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? blurSigma : blurSigma * 0.6,
          sigmaY: isScrolled ? blurSigma : blurSigma * 0.6,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: showDivider ? Border(bottom: BorderSide(color: divider, width: 1)) : null,
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  if (leadingWidget != null) ...[
                    const SizedBox(width: 6),
                    leadingWidget,
                    const SizedBox(width: 6),
                  ] else
                    const SizedBox(width: 12),

                  Expanded(
                    child: DefaultTextStyle(
                      style: theme.appBarTheme.titleTextStyle ??
                          theme.textTheme.titleMedium ??
                          const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: title,
                      ),
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