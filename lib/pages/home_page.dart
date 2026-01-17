import 'package:flutter/material.dart';

import '../theme/theme_store.dart';

class HomePage extends StatelessWidget {
  final ScrollController scrollController;

  const HomePage({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 24),
      children: [
        Text(
          '主页（空壳）',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          '这里只保留容器能力：AppShell + Drawer + Settings + Personalization。\n'
          '业务/筛选/图源全部删除，后面你重写时不会被历史结构拖死。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(store.cardRadius),
          ),
          child: Text(
            'cardRadius=${store.cardRadius}\nimageRadius=${store.imageRadius}\n'
            'mode=${store.mode}\naccent=${store.accentName}',
          ),
        ),
      ],
    );
  }
}