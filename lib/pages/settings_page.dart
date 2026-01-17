import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String resultOpenPersonalization = 'open_personalization';

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
            onTap: () => Navigator.of(context).pop(resultOpenPersonalization),
          ),
        ],
      ),
    );
  }
}