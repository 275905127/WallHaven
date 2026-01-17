import 'package:flutter/material.dart';
import 'personalization_page.dart';

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
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题 / 个性化'),
            subtitle: const Text('浅色 / 深色 / 自定义颜色 / 圆角'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const PersonalizationPage()),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('版本信息'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'app',
              applicationVersion: 'dev',
            ),
          ),
        ],
      ),
    );
  }
}