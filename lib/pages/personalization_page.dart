// lib/pages/personalization_page.dart
import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/app_intent.dart';
import '../theme/theme_store.dart';
import '../widgets/settings_widgets.dart';

class PersonalizationPage extends StatelessWidget {
  final AppController controller;
  const PersonalizationPage({super.key, required this.controller});

  String _modeLabel(ThemeMode m) {
    return switch (m) {
      ThemeMode.system => '跟随系统',
      ThemeMode.light => '浅色',
      ThemeMode.dark => '深色',
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('主题 / 个性化'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => controller.dispatch(const PopRouteIntent()),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const SectionHeader(title: '主题模式'),
              SettingsGroup(
                items: [
                  SettingsItem(
                    icon: Icons.brightness_6_outlined,
                    title: '模式',
                    subtitle: _modeLabel(store.preferredMode),
                    onTap: () => _showModeSheet(context, store),
                  ),
                  SettingsItem(
                    icon: Icons.toggle_on_outlined,
                    title: '启用强制主题',
                    subtitle: store.enableThemeMode ? '已启用（使用上方模式）' : '未启用（跟随系统）',
                    trailing: Switch(
                      value: store.enableThemeMode,
                      onChanged: (v) => controller.dispatch(SetEnableThemeModeIntent(v)),
                    ),
                    onTap: () => controller.dispatch(SetEnableThemeModeIntent(!store.enableThemeMode)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const SectionHeader(title: '自定义颜色'),
              SettingsGroup(
                items: [
                  SettingsItem(
                    icon: Icons.brush_outlined,
                    title: '启用自定义背景/卡片颜色',
                    subtitle: store.enableCustomColors ? '已启用（强制浅色模式）' : '未启用',
                    trailing: Switch(
                      value: store.enableCustomColors,
                      onChanged: (v) => controller.dispatch(SetEnableCustomColorsIntent(v)),
                    ),
                    onTap: () => controller.dispatch(SetEnableCustomColorsIntent(!store.enableCustomColors)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const SectionHeader(title: '强调色'),
              _accentRow(context, store),
              const SizedBox(height: 18),

              const SectionHeader(title: '圆角'),
              _radiusCard(context, store),
            ],
          ),
        );
      },
    );
  }

  void _showModeSheet(BuildContext context, ThemeStore store) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((m) {
              return RadioListTile<ThemeMode>(
                value: m,
                groupValue: store.preferredMode,
                title: Text(_modeLabel(m)),
                onChanged: (v) {
                  if (v == null) return;
                  controller.dispatch(SetPreferredModeIntent(v));
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _accentRow(BuildContext context, ThemeStore store) {
    final presets = <({Color c, String name})>[
      (c: Colors.blue, name: '蓝色'),
      (c: Colors.amber, name: '黄色'),
      (c: Colors.green, name: '绿色'),
      (c: Colors.purple, name: '紫色'),
      (c: Colors.red, name: '红色'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: presets.map((p) {
        final selected = store.accentColor.toARGB32() == p.c.toARGB32();
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => controller.dispatch(SetAccentIntent(p.c, p.name)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                width: selected ? 2 : 1,
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: p.c,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(p.name),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _radiusCard(BuildContext context, ThemeStore store) {
    Widget slider({
      required String title,
      required double value,
      required double min,
      required double max,
      required ValueChanged<double> onChanged,
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(store.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title  ${value.toStringAsFixed(1)}'),
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        slider(
          title: '卡片圆角',
          value: store.cardRadius,
          min: 8,
          max: 28,
          onChanged: (v) => controller.dispatch(SetCardRadiusIntent(v)),
        ),
        const SizedBox(height: 12),
        slider(
          title: '图片圆角',
          value: store.imageRadius,
          min: 6,
          max: 24,
          onChanged: (v) => controller.dispatch(SetImageRadiusIntent(v)),
        ),
      ],
    );
  }
}