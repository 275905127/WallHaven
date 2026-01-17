import 'package:flutter/material.dart';
import '../design/app_tokens.dart';
import '../theme/theme_store.dart';

class SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<SettingsItem> items;
  const SettingsGroup({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final double largeRadius = ThemeScope.of(context).cardRadius;

    const double jointRadius = 4.0;

    BorderRadius _radiusFor(int index) {
      final isFirst = index == 0;
      final isLast = index == items.length - 1;
      final isSingle = items.length == 1;

      if (isSingle) return BorderRadius.circular(largeRadius);

      if (isFirst) {
        return BorderRadius.only(
          topLeft: Radius.circular(largeRadius),
          topRight: Radius.circular(largeRadius),
          bottomLeft: const Radius.circular(jointRadius),
          bottomRight: const Radius.circular(jointRadius),
        );
      }

      if (isLast) {
        return BorderRadius.only(
          topLeft: const Radius.circular(jointRadius),
          topRight: const Radius.circular(jointRadius),
          bottomLeft: Radius.circular(largeRadius),
          bottomRight: Radius.circular(largeRadius),
        );
      }

      return BorderRadius.circular(jointRadius);
    }

    Widget _divider() {
      return Container(
        height: tokens.dividerThickness,
        color: tokens.dividerColor,
      );
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final br = _radiusFor(index);
        final isLast = index == items.length - 1;

        return Column(
          children: [
            Material(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: br),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: br,
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 24, color: theme.iconTheme.color),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (item.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      item.trailing ?? Icon(Icons.chevron_right, color: tokens.chevronColor),
                    ],
                  ),
                ),
              ),
            ),
            if (!isLast) _divider(),
          ],
        );
      }),
    );
  }
}