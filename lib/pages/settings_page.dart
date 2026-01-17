import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/app_intent.dart';

class SettingsPage extends StatelessWidget {
  final AppController controller;

  const SettingsPage({
    super.key,
    required this.controller,
  });

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
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题 / 个性化'),
            subtitle: const Text('浅色 / 深色 / 自定义颜色 / 圆角'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => controller.dispatch(const OpenPersonalizationIntent()),
          ),
        ],
      ),
    );
  }
}