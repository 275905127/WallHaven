// lib/widgets/settings_widgets.dart
import 'package:flutter/material.dart';
import '../theme/theme_store.dart';
import '../theme/app_tokens.dart';

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
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
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

    BorderRadius _radiusFor(int index) {
      final bool isFirst = index == 0;
      final bool isLast = index == items.length - 1;
      final bool isSingle = items.length == 1;

      if (isSingle) return BorderRadius.circular(largeRadius);
      if (isFirst) {
        return BorderRadius.only(
          topLeft: Radius.circular(largeRadius),
          topRight: Radius.circular(largeRadius),
          bottomLeft: Radius.circular(tokens.smallRadius),
          bottomRight: Radius.circular(tokens.smallRadius),
        );
      }
      if (isLast) {
        return BorderRadius.only(
          topLeft: Radius.circular(tokens.smallRadius),
          topRight: Radius.circular(tokens.smallRadius),
          bottomLeft: Radius.circular(largeRadius),
          bottomRight: Radius.circular(largeRadius),
        );
      }
      return BorderRadius.circular(tokens.smallRadius);
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final br = _radiusFor(index);
        final bool isLast = index == items.length - 1;

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: br),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: br,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(item.icon, color: theme.iconTheme.color, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(item.subtitle!, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                              ],
                            ],
                          ),
                        ),
                        item.trailing ??
                            Icon(
                              Icons.chevron_right,
                              color: tokens.chevronColor,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isLast) Container(height: tokens.dividerThickness, color: tokens.dividerColor),
          ],
        );
      }),
    );
  }
}