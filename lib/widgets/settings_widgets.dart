import 'package:flutter/material.dart';
import '../theme/theme_store.dart'; // 引入 Store

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
    required this.onTap
  });
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<SettingsItem> items;
  static const double smallRadius = 4.0; // 小圆角保持不变，用于连接处
  
  const SettingsGroup({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 🌟 核心修复：确保这里使用的是 cardRadius 而不是旧的 cornerRadius
    final double largeRadius = ThemeScope.of(context).cardRadius;
    
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final bool isFirst = index == 0;
        final bool isLast = index == items.length - 1;
        final bool isSingle = items.length == 1;
        
        BorderRadius borderRadius;
        if (isSingle) borderRadius = BorderRadius.circular(largeRadius);
        else if (isFirst) borderRadius = BorderRadius.only(topLeft: Radius.circular(largeRadius), topRight: Radius.circular(largeRadius), bottomLeft: Radius.circular(smallRadius), bottomRight: Radius.circular(smallRadius));
        else if (isLast) borderRadius = BorderRadius.only(topLeft: Radius.circular(smallRadius), topRight: Radius.circular(smallRadius), bottomLeft: Radius.circular(largeRadius), bottomRight: Radius.circular(largeRadius));
        else borderRadius = BorderRadius.circular(smallRadius);

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: borderRadius),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: borderRadius,
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
                              if (item.subtitle != null) ...[const SizedBox(height: 2), Text(item.subtitle!, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color))],
                            ],
                          ),
                        ),
                        item.trailing ?? Icon(Icons.chevron_right, color: theme.brightness == Brightness.dark ? const Color(0xFF666666) : const Color(0xFFC7C7CC)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isLast) Container(height: 2, color: theme.dividerColor),
          ],
        );
      }),
    );
  }
}
