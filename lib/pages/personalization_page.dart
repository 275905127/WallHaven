import 'package:flutter/material.dart';

import '../theme/theme_store.dart';
import '../widgets/settings_widgets.dart';

class PersonalizationPage extends StatelessWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('主题 / 个性化')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const SectionHeader(title: '主题模式'),
              SettingsGroup(
                items: [
                  SettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: '启用主题模式开关',
                    subtitle: '关闭则跟随系统',
                    trailing: Switch(
                      value: store.enableThemeMode,
                      onChanged: store.setEnableThemeMode,
                    ),
                    onTap: () => store.setEnableThemeMode(!store.enableThemeMode),
                  ),
                  SettingsItem(
                    icon: Icons.brightness_6_outlined,
                    title: '偏好主题',
                    subtitle: store.preferredMode.name,
                    onTap: () async {
                      final v = await showModalBottomSheet<ThemeMode>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('system'),
                                onTap: () => Navigator.pop(ctx, ThemeMode.system),
                              ),
                              ListTile(
                                title: const Text('light'),
                                onTap: () => Navigator.pop(ctx, ThemeMode.light),
                              ),
                              ListTile(
                                title: const Text('dark'),
                                onTap: () => Navigator.pop(ctx, ThemeMode.dark),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (v != null) store.setPreferredMode(v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const SectionHeader(title: '圆角'),
              SettingsGroup(
                items: [
                  SettingsItem(
                    icon: Icons.rounded_corner,
                    title: '卡片圆角',
                    subtitle: store.cardRadius.toStringAsFixed(1),
                    trailing: SizedBox(
                      width: 160,
                      child: Slider(
                        min: 8,
                        max: 28,
                        value: store.cardRadius,
                        onChanged: store.setCardRadius,
                      ),
                    ),
                    onTap: () {},
                  ),
                  SettingsItem(
                    icon: Icons.image_outlined,
                    title: '图片圆角',
                    subtitle: store.imageRadius.toStringAsFixed(1),
                    trailing: SizedBox(
                      width: 160,
                      child: Slider(
                        min: 0,
                        max: 24,
                        value: store.imageRadius,
                        onChanged: store.setImageRadius,
                      ),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const SectionHeader(title: '自定义颜色'),
              SettingsGroup(
                items: [
                  SettingsItem(
                    icon: Icons.color_lens_outlined,
                    title: '启用自定义背景/卡片色',
                    subtitle: '启用后强制 Light 模式（防止深色冲突）',
                    trailing: Switch(
                      value: store.enableCustomColors,
                      onChanged: store.setEnableCustomColors,
                    ),
                    onTap: () => store.setEnableCustomColors(!store.enableCustomColors),
                  ),
                  SettingsItem(
                    icon: Icons.format_paint_outlined,
                    title: '背景色（示例：黑/白切换）',
                    subtitle: store.customBackgroundColor?.value.toRadixString(16) ?? '(null)',
                    onTap: () {
                      final cur = store.customBackgroundColor;
                      if (cur == null || cur.value != 0xFF000000) {
                        store.setCustomBackgroundColor(const Color(0xFF000000));
                      } else {
                        store.setCustomBackgroundColor(const Color(0xFFFFFFFF));
                      }
                    },
                  ),
                  SettingsItem(
                    icon: Icons.crop_square_outlined,
                    title: '卡片色（示例：灰/深灰切换）',
                    subtitle: store.customCardColor?.value.toRadixString(16) ?? '(null)',
                    onTap: () {
                      final cur = store.customCardColor;
                      if (cur == null || cur.value != 0xFF414141) {
                        store.setCustomCardColor(const Color(0xFF414141));
                      } else {
                        store.setCustomCardColor(const Color(0xFFF3F3F3));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}