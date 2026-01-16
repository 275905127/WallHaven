// lib/pages/sub_pages.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/theme_store.dart';
import '../theme/app_tokens.dart';
import '../widgets/foggy_app_bar.dart';
import '../widgets/settings_widgets.dart';

// 你这里确实需要 SourceConfig 等类型
import '../sources/source_plugin.dart';

// ==========================================
// 1. 🎨 个性化二级页
// ==========================================
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
      // ✅ 替换 deprecated 的 .value
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

  Widget _themeModeFold(BuildContext context, ThemeStore store) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final bool disabled = store.enableCustomColors;

    final bool switchValue = disabled ? false : store.enableThemeMode;
    final bool expanded = switchValue;

    final Color fg =
        disabled ? tokens.disabledFg : (theme.textTheme.bodyLarge?.color ?? Colors.white);

    final BorderRadius headerRadius = BorderRadius.only(
      topLeft: Radius.circular(store.cardRadius),
      topRight: Radius.circular(store.cardRadius),
      bottomLeft: Radius.circular(expanded ? tokens.smallRadius : store.cardRadius),
      bottomRight: Radius.circular(expanded ? tokens.smallRadius : store.cardRadius),
    );

    final BorderRadius bodyRadius = BorderRadius.only(
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

    // ✅ 新 API：RadioGroup(value/onChanged) + RadioListTile
    // - 不再使用 groupValue/onChanged（那些已经 deprecated）
    // - toggleable=true 允许再点一次取消（你原来的“关闭/不限”逻辑在这里不需要）
    final bodyCard = Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: bodyRadius),
      clipBehavior: Clip.antiAlias,
      child: RadioGroup<ThemeMode>(
       groupValue: store.preferredMode,
       onChanged: disabled ? null : (ThemeMode v) => store.setPreferredMode(v),
       child: Column(
        children: [
         RadioTile<ThemeMode>(
          value: ThemeMode.system,
          title: const Text("系统 (默认)"),
         ),
         Container(height: tokens.dividerThickness, color: tokens.dividerColor),
         RadioTile<ThemeMode>(
          value: ThemeMode.light,
          title: const Text("浅色"),
         ),
         Container(height: tokens.dividerThickness, color: tokens.dividerColor),
         RadioTile<ThemeMode>(
          value: ThemeMode.dark,
          title: const Text("深色"),
        ),
      ],
    ),
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
        // ✅ 替换 deprecated 的 .value
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
                      onChanged: (val) => store.setEnableCustomColors(val),
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
                        (c) => store.setCustomBackgroundColor(c),
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
                        (c) => store.setCustomCardColor(c),
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
                (val) => store.setCardRadius(val),
                () => store.savePreferences(),
              ),
              const SizedBox(height: 12),
              _radiusSlider(
                context,
                "图片圆角",
                store.imageRadius,
                (val) => store.setImageRadius(val),
                () => store.savePreferences(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 2. 图源管理二级页（插件化：操作 SourceConfig）
// ==========================================
class SourceManagementPage extends StatefulWidget {
  const SourceManagementPage({super.key});

  @override
  State<SourceManagementPage> createState() => _SourceManagementPageState();
}

class _SourceManagementPageState extends State<SourceManagementPage> {
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

  bool _isBuiltInConfig(SourceConfig c) => c.id.startsWith('default_');

  String _baseUrlOf(SourceConfig c) {
    final v = c.settings['baseUrl'];
    return (v is String) ? v : '';
  }

  String? _apiKeyOf(SourceConfig c) {
    final v = c.settings['apiKey'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  String? _usernameOf(SourceConfig c) {
    final v = c.settings['username'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  void _showAddSourceDialog(BuildContext context) {
    final store = ThemeScope.of(context);

    final jsonCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final listKeyCtrl = TextEditingController(text: "@direct");

    String? errorText;

    void toast(String msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    bool looksLikeJson(String s) {
      final t = s.trim();
      return t.startsWith('{') && t.endsWith('}');
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          return DefaultTabController(
            length: 2,
            child: AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("添加图源"),
                  SizedBox(height: 10),
                  TabBar(
                    tabs: [
                      Tab(text: "A 粘贴配置"),
                      Tab(text: "B 表单添加"),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Flexible(
                      child: TabBarView(
                        children: [
                          // A：粘贴 JSON
                          SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                TextField(
                                  controller: jsonCtrl,
                                  minLines: 8,
                                  maxLines: 14,
                                  decoration: const InputDecoration(
                                    labelText: "配置 JSON",
                                    hintText: "直接粘贴完整配置（包含 name/baseUrl/listKey/filters 等）",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() => errorText = null),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      const sample = {
                                        "name": "示例 (随机直链)",
                                        "baseUrl": "https://example.com/api/random",
                                        "listKey": "@direct",
                                        "filters": []
                                      };
                                      jsonCtrl.text =
                                          const JsonEncoder.withIndent("  ").convert(sample);
                                      setState(() => errorText = null);
                                    },
                                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                                    label: const Text("填充示例"),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),

                          // B：表单生成 JSON（最简）
                          SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "名称 *",
                                    hintText: "例如：Luvbree（随机直链）",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() => errorText = null),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: urlCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "API 地址 *",
                                    hintText: "例如：https://www.luvbree.com/api/image/random",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() => errorText = null),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: listKeyCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "listKey（默认 @direct）",
                                    hintText: "@direct 表示返回的是直链",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => setState(() => errorText = null),
                                ),
                                const SizedBox(height: 12),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "说明：这里先生成最简配置（filters 为空）。\n你要更复杂的 filters，走 A 粘贴配置。",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () {
                    final tab = DefaultTabController.of(dialogCtx).index;

                    try {
                      setState(() => errorText = null);

                      if (tab == 0) {
                        final raw = jsonCtrl.text.trim();
                        if (raw.isEmpty) {
                          setState(() => errorText = "你没粘贴任何配置。");
                          return;
                        }
                        if (!looksLikeJson(raw)) {
                          setState(() => errorText = "这看起来不像 JSON（需要以 { 开头，以 } 结尾）。");
                          return;
                        }

                        store.addSourceFromJsonString(raw);

                        Navigator.pop(dialogCtx);
                        toast("已添加图源");
                        return;
                      }

                      final name = nameCtrl.text.trim();
                      final url = urlCtrl.text.trim();
                      final listKey = listKeyCtrl.text.trim().isEmpty ? "@direct" : listKeyCtrl.text.trim();

                      if (name.isEmpty || url.isEmpty) {
                        setState(() => errorText = "名称和 API 地址是必填。");
                        return;
                      }

                      final cfg = <String, dynamic>{
                        "name": name,
                        "baseUrl": url,
                        "listKey": listKey,
                        "filters": <dynamic>[],
                      };

                      store.addSourceFromJsonString(jsonEncode(cfg));

                      Navigator.pop(dialogCtx);
                      toast("已添加图源");
                    } catch (e) {
                      setState(() => errorText = "添加失败：$e");
                    }
                  },
                  child: const Text("添加"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditConfigDialog(BuildContext context, SourceConfig cfg) {
    final store = ThemeScope.of(context);

    final builtIn = _isBuiltInConfig(cfg);

    final nameCtrl = TextEditingController(text: cfg.name);
    final urlCtrl = TextEditingController(text: _baseUrlOf(cfg));
    final userCtrl = TextEditingController(text: _usernameOf(cfg) ?? '');
    final keyCtrl = TextEditingController(text: _apiKeyOf(cfg) ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(builtIn ? "配置图源 (默认插件)" : "编辑图源"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "名称", filled: true),
                enabled: !builtIn,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: "API 地址", filled: true),
                enabled: !builtIn,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: "用户名 (可选)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(labelText: "API Key (可选)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              final nextSettings = Map<String, dynamic>.from(cfg.settings);

              if (!builtIn) {
                final u = urlCtrl.text.trim();
                if (u.isNotEmpty) nextSettings['baseUrl'] = u;
              }

              nextSettings['username'] = userCtrl.text.trim().isEmpty ? null : userCtrl.text.trim();
              nextSettings['apiKey'] = keyCtrl.text.trim().isEmpty ? null : keyCtrl.text.trim();

              final updated = cfg.copyWith(
                name: builtIn ? cfg.name : nameCtrl.text.trim(),
                settings: nextSettings,
              );

              store.updateSourceConfig(updated);
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final currentId = store.currentSourceConfig.id;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FoggyAppBar(
            title: const Text("图源管理"),
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
              const SectionHeader(title: "已添加的图源"),
              SettingsGroup(
                items: store.sourceConfigs.map((cfg) {
                  final builtIn = _isBuiltInConfig(cfg);
                  final baseUrl = _baseUrlOf(cfg);
                  final apiKey = _apiKeyOf(cfg);
                  final isCurrent = cfg.id == currentId;

                  var subtitle = baseUrl.isEmpty ? "(未配置 baseUrl)" : baseUrl;
                  subtitle += "\n插件: ${cfg.pluginId}";
                  if (apiKey != null) subtitle += "\n🔑 已配置 API Key";
                  if (isCurrent) subtitle += "\n✅ 当前使用";

                  return SettingsItem(
                    icon: builtIn ? Icons.verified : Icons.link,
                    title: cfg.name,
                    subtitle: subtitle,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent) const Icon(Icons.check, size: 18),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditConfigDialog(context, cfg),
                        ),
                        if (!builtIn)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => store.removeSourceConfig(cfg.id),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Text("默认", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                      ],
                    ),
                    onTap: () => store.setCurrentSourceConfig(cfg.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SettingsGroup(
                items: [
                  SettingsItem(
                    icon: Icons.add_circle_outline,
                    title: "添加新图源",
                    onTap: () => _showAddSourceDialog(context),
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