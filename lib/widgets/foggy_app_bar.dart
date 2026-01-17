import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../design/app_tokens.dart';

class FoggyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final bool isScrolled;

  final Widget? leading;
  final List<Widget> actions;

  /// 是否自动给一个“菜单按钮”（仅当 Scaffold 有 drawer 且 leading 为空时）
  final bool autoImplyDrawer;

  const FoggyAppBar({
    super.key,
    required this.title,
    required this.isScrolled,
    this.leading,
    this.actions = const [],
    this.autoImplyDrawer = true,
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
    final tokens = theme.extension<AppTokens>();
    if (tokens == null) {
      // 你项目是强 tokens 体系，这里直接暴露问题，不要默默降级
      throw StateError('AppTokens not found in ThemeData.extensions');
    }

    final t = isScrolled ? 1.0 : 0.0;

    final opacity = lerpDouble(
          tokens.appBarFogOpacityIdle,
          tokens.appBarFogOpacityScrolled,
          t,
        )!
        .clamp(0.0, 1.0);

    final blurSigma = lerpDouble(
      tokens.appBarBlurSigmaIdle,
      tokens.appBarBlurSigmaScrolled,
      t,
    )!;

    final bg = theme.scaffoldBackgroundColor.withOpacity(opacity);

    final showDivider = isScrolled && tokens.appBarDividerOpacityScrolled > 0;
    final dividerColor =
        theme.dividerColor.withOpacity(tokens.appBarDividerOpacityScrolled.clamp(0.0, 1.0));

    final leadingWidget = _buildLeading(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: dividerColor,
                      width: tokens.appBarDividerWidth,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.appBarHPadding),
                child: Row(
                  children: [
                    if (leadingWidget != null) ...[
                      SizedBox(width: tokens.appBarLeadingGap),
                      leadingWidget,
                      SizedBox(width: tokens.appBarLeadingGap),
                    ],

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
                    SizedBox(width: tokens.appBarTrailingGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 兼容 dart:ui lerpDouble
double? lerpDouble(double a, double b, double t) => a + (b - a) * t;