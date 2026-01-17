import 'package:flutter/material.dart';

import '../theme/theme_store.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 24),
      children: [
        Text(
          '主页（空壳）',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          '这里只保留 App 容器能力：\n'
          '- AppShell\n'
          '- Drawer（仅设置入口）\n'
          '- Settings / Personalization\n'
          '- Theme / Tokens / FoggyAppBar\n\n'
          '业务 / 图源 / 筛选已全部剥离。\n'
          '你后面从这里开始重写，不会被任何历史结构拖死。',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(store.cardRadius),
          ),
          child: Text(
            'Debug:\n'
            'cardRadius = ${store.cardRadius}\n'
            'imageRadius = ${store.imageRadius}\n'
            'mode = ${store.mode}\n'
            'accent = ${store.accentName}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}