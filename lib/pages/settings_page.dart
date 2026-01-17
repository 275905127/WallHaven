// lib/pages/settings_page.dart
import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/app_intent.dart';
import '../widgets/settings_widgets.dart';

class SettingsPage extends StatelessWidget {
  final AppController controller;
  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.dispatch(const PopRouteIntent()),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SectionHeader(title: '个性化'),
          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.palette_outlined,
                title: '主题 / 个性化',
                subtitle: '浅色 / 深色 / 自定义颜色 / 圆角',
                onTap: () => controller.dispatch(const OpenPersonalizationIntent()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}