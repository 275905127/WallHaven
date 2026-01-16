// lib/pages/personalization_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';
import '../widgets/settings_widgets.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  final ScrollController _sc = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      final scrolled = _sc.offset > 0;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return "系统 (默认)";
      case ThemeMode.light:
        return "浅色";
      case ThemeMode.dark:
        return "深色";
    }
  }

  void _showHexColorDialog(
    BuildContext context,
    String title,
    Color? currentColor,
    ValueChanged<Color?> onColorChanged,
  ) {
    String initHex = "";
    if (currentColor != null) {
      initHex = currentColor
          .toARGB32()
          .toRadixString(16)
          .toUpperCase()
          .padLeft(8, '0')
          .substring(2);
    }

    final textCtrl = TextEditingController(text: initHex);
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                decoration: InputDecoration(
                  labelText: "Hex 颜色代码",
                  hintText: "例如: FFFFFF",
                  prefixText: "# ",
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final v = val.trim();
                  if (v.isNotEmpty && v.length != 6) {
                    setState(() => errorText = "请输入 6 位颜色代码");
                  } else {
                    setState(() => errorText = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("预览: "),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _parseColor(textCtrl.text) ?? Colors.transparent,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                onColorChanged(null);
                Navigator.pop(context);
              },
              child: const Text("恢复默认", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                final color = _parseColor(textCtrl.text);
                if (color != null) {
                  onColorChanged(color);
                  Navigator.pop(context);
                } else {
                  setState(() => errorText = "无效的颜色代码");
                }
              },
              child: const Text("确定"),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String hex) {
    try {
      var t = hex.trim().replaceAll("#", "");
      if (t.isEmpty) return null;
      if (t.length == 6) t = "FF$t";
      if (t.length != 8) return null;
      return Color(int.parse(t, radix: 16));
    } catch (_) {
      return null;
    }
  }

  Widget _radiusSlider(
    BuildContext context,
    String title,
    double value,
    ValueChanged<double> onChanged,
    VoidCallback onSave,
  ) {
    final theme = Theme.of(context);
    final store = ThemeScope.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(store.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
              ),
              Text(
                "${value.toInt()} px",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0.0,
            max: 40.0,
            divisions: 40,
            onChanged: onChanged,
            onChangeEnd: (_) => onSave(),
          ),
        ],
      ),
    );
  }

  Widget _modeRadioRow({
    required BuildContext context,
    required AppTokens tokens,
    required bool disabled,
    required ThemeMode value,
    required String title,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode> onPick,
  }) {
    final theme = Theme.of(context);
    final fg = disabled ? tokens.disabledFg : (theme.textTheme.bodyLarge?.color ?? Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : () => onPick(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: _RadioDot(
                  selected: groupValue == value,
                  disabled: disabled,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeModeFold(BuildContext context, ThemeStore store) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final disabled = store.enableCustomColors;

    final switchValue = disabled ? false : store.enableThemeMode;
    final expanded = switchValue;

    final fg = disabled ? tokens.disabledFg : (theme.textTheme.bodyLarge?.color ?? Colors.white);

    final headerRadius = BorderRadius.only(
      topLeft: Radius.circular(store.cardRadius),
      topRight: Radius.circular(store.cardRadius),
      bottomLeft: Radius.circular(expanded ? tokens.smallRadius : store.cardRadius),
      bottomRight: Radius.circular(expanded ? tokens.smallRadius : store.cardRadius),
    );

    final bodyRadius = BorderRadius.only(
      topLeft: Radius.circular(tokens.smallRadius),
      topRight: Radius.circular(tokens.smallRadius),
      bottomLeft: Radius.circular(store.cardRadius),
      bottomRight: Radius.circular(store.cardRadius),
    );

    final header = Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: headerRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => store.setEnableThemeMode(!store.enableThemeMode),
          borderRadius: headerRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: fg, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("颜色模式", style: TextStyle(fontSize: 16, color: fg)),
                      const SizedBox(height: 2),
                      Text(
                        disabled
                            ? "已被「自定义颜色」接管"
                            : (store.enableThemeMode ? _modeLabel(store.preferredMode) : "关闭：跟随系统"),
                        style: TextStyle(
                          fontSize: 13,
                          color: disabled ? fg : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: switchValue,
                  onChanged: disabled ? null : (v) => store.setEnableThemeMode(v),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final bodyCard = Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: bodyRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _modeRadioRow(
            context: context,
            tokens: tokens,
            disabled: disabled,
            value: ThemeMode.system,
            title: "系统 (默认)",
            groupValue: store.preferredMode,
            onPick: store.setPreferredMode,
          ),
          Container(height: tokens.dividerThickness, color: tokens.dividerColor),
          _modeRadioRow(
            context: context,
            tokens: tokens,
            disabled: disabled,
            value: ThemeMode.light,
            title: "浅色",
            groupValue: store.preferredMode,
            onPick: store.setPreferredMode,
          ),
          Container(height: tokens.dividerThickness, color: tokens.dividerColor),
          _modeRadioRow(
            context: context,
            tokens: tokens,
            disabled: disabled,
            value: ThemeMode.dark,
            title: "深色",
            groupValue: store.preferredMode,
            onPick: store.setPreferredMode,
          ),
        ],
      ),
    );

    final expandedBlock = Column(
      children: [
        Container(height: tokens.dividerThickness, color: tokens.dividerColor),
        bodyCard,
      ],
    );

    return Column(
      children: [
        header,
        AnimatedSize(
          duration: tokens.expandDuration,
          curve: tokens.expandCurve,
          alignment: Alignment.topCenter,
          child: expanded ? expandedBlock : const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final bgHex = store.customBackgroundColor != null
            ? "#${store.customBackgroundColor!.toARGB32().toRadixString(16).toUpperCase().substring(2)}"
            : "默认";
        final cardHex = store.customCardColor != null
            ? "#${store.customCardColor!.toARGB32().toRadixString(16).toUpperCase().substring(2)}"
            : "默认";

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FoggyAppBar(
            title: const Text("个性化"),
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
              const SectionHeader(title: "界面风格"),
              _themeModeFold(context, store),
              const SizedBox(height: 12),
              SettingsGroup(
                items: [
                  SettingsItem(
                    icon: Icons.palette_outlined,
                    title: "自定义颜色",
                    trailing: Switch(
                      value: store.enableCustomColors,
                      onChanged: store.setEnableCustomColors,
                    ),
                    onTap: () => store.setEnableCustomColors(!store.enableCustomColors),
                  ),
                  if (store.enableCustomColors) ...[
                    SettingsItem(
                      icon: Icons.format_paint_outlined,
                      title: "全局背景颜色",
                      subtitle: bgHex,
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: store.customBackgroundColor ?? Colors.transparent,
                          border: Border.all(color: Colors.grey.withAlpha(128)),
                          shape: BoxShape.circle,
                        ),
                        child: store.customBackgroundColor == null
                            ? const Icon(Icons.auto_awesome, size: 14, color: Colors.grey)
                            : null,
                      ),
                      onTap: () => _showHexColorDialog(
                        context,
                        "全局背景颜色",
                        store.customBackgroundColor,
                        store.setCustomBackgroundColor,
                      ),
                    ),
                    SettingsItem(
                      icon: Icons.dashboard_customize_outlined,
                      title: "卡片颜色",
                      subtitle: cardHex,
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: store.customCardColor ?? Colors.transparent,
                          border: Border.all(color: Colors.grey.withAlpha(128)),
                          shape: BoxShape.circle,
                        ),
                        child: store.customCardColor == null
                            ? const Icon(Icons.auto_awesome, size: 14, color: Colors.grey)
                            : null,
                      ),
                      onTap: () => _showHexColorDialog(
                        context,
                        "卡片颜色",
                        store.customCardColor,
                        store.setCustomCardColor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: "圆角设置"),
              _radiusSlider(
                context,
                "全局圆角",
                store.cardRadius,
                store.setCardRadius,
                store.savePreferences,
              ),
              const SizedBox(height: 12),
              _radiusSlider(
                context,
                "图片圆角",
                store.imageRadius,
                store.setImageRadius,
                store.savePreferences,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final bool disabled;

  const _RadioDot({
    required this.selected,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final mono = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    final border = disabled ? tokens.disabledFg.withAlpha(90) : mono.withAlpha(120);
    final fill = disabled ? tokens.disabledFg.withAlpha(90) : mono;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: tokens.expandDuration,
        curve: tokens.expandCurve,
        width: selected ? 10 : 0,
        height: selected ? 10 : 0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? fill : Colors.transparent,
        ),
      ),
    );
  }
}