// lib/pages/settings_page.dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../widgets/foggy_app_bar.dart';
import '../widgets/settings_widgets.dart';

import 'personalization_page.dart';
import 'source_management_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _sc = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (_sc.offset > 0 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_sc.offset <= 0 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(
        title: const Text("设置"),
        isScrolled: _isScrolled,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        controller: _sc,
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
        children: [
          const SectionHeader(title: "应用"),
          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.palette_outlined,
                title: "主题 / 个性化",
                subtitle: "浅色 / 深色 / 自定义颜色 / 圆角",
                onTap: () => _push(context, const PersonalizationPage()),
              ),
              Container(height: tokens.dividerThickness, color: tokens.dividerColor),
              SettingsItem(
                icon: Icons.source_outlined,
                title: "图源管理",
                subtitle: "添加 / 编辑 / 切换图源",
                onTap: () => _push(context, const SourceManagementPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "信息"),
          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.info_outline,
                title: "关于",
                subtitle: "版本信息",
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: "wallhaven",
                  applicationVersion: "dev",
                  applicationIcon: const Icon(Icons.wallpaper_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}