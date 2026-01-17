// lib/widgets/foggy_app_bar.dart
import 'dart:ui' show ImageFilter, lerpDouble;

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
      throw StateError('AppTokens not found in ThemeData.extensions');
    }

    // 二态：组件只负责“选哪个值”，不负责“怎么算更好看”
    final double opacity = (isScrolled ? tokens.appBarFogOpacityScrolled : tokens.appBarFogOpacityIdle)
        .clamp(0.0, 1.0);

    final double blurSigma = isScrolled ? tokens.appBarBlurSigmaScrolled : tokens.appBarBlurSigmaIdle;

    final Color bg = theme.scaffoldBackgroundColor.withOpacity(opacity);

    final bool showStroke = isScrolled && tokens.appBarBottomStrokeOpacityScrolled > 0;
    final Color strokeColor = theme.dividerColor.withOpacity(
      tokens.appBarBottomStrokeOpacityScrolled.clamp(0.0, 1.0),
    );

    final leadingWidget = _buildLeading(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: showStroke
                ? Border(
                    bottom: BorderSide(
                      color: strokeColor,
                      width: tokens.appBarBottomStrokeWidth,
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
                    ] else
                      // 没 leading 时保持左侧呼吸感（同样走 tokens）
                      SizedBox(width: tokens.appBarLeadingGap * 2),

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