import 'dart:ui';

import '../design/app_tokens.dart';

class FoggyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final bool isScrolled;
  final Widget? leading;
  final List<Widget> actions;

  const FoggyAppBar({
    super.key,
    required this.title,
    required this.isScrolled,
    this.leading,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final bg = theme.scaffoldBackgroundColor;

    final fogOpacity = isScrolled ? tokens.appBarFogOpacity : 0.0;
    final blur = isScrolled ? tokens.appBarBlurSigma : 0.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: bg.withOpacity(fogOpacity),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(isScrolled ? tokens.appBarBottomStrokeOpacity : 0.0),
                width: 1,
              ),
            ),
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
                      ),
                  Expanded(
                    child: DefaultTextStyle(
                      style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleMedium!,
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