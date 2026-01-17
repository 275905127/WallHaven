// lib/pages/settings_page.dart
import 'package:flutter/material.dart';

import '../widgets/settings_widgets.dart';
import 'personalization_page.dart';
import 'source_management_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SectionHeader(title: "外观"),
          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.palette_outlined,
                title: '主题 / 个性化',
                subtitle: '浅色 / 深色 / 自定义颜色 / 圆角',
                onTap: () => _push(context, const PersonalizationPage()),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const SectionHeader(title: "内容"),
          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.source_outlined,
                title: '图源管理',
                subtitle: '添加 / 编辑 / 切换图源',
                onTap: () => _push(context, const SourceManagementPage()),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const SectionHeader(title: "其他"),
          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.info_outline,
                title: '关于',
                subtitle: '版本信息',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'wallhaven',
                  applicationVersion: 'dev',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}