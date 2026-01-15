// lib/pages/sub_pages.dart
import 'package:flutter/material.dart';
import '../theme/theme_store.dart';
import '../theme/app_tokens.dart';
import '../widgets/foggy_app_bar.dart';
import '../widgets/settings_widgets.dart';
import '../models/image_source.dart';

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
      if (_sc.offset > 0 && !_isScrolled) setState(() => _isScrolled = true);
      else if (_sc.offset <= 0 && _isScrolled) setState(() => _isScrolled = false);
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

  void _showHexColorDialog(BuildContext context, String title, Color? currentColor, Function(Color?) onColorChanged) {
    String initHex = "";
    if (currentColor != null) {
      initHex = currentColor.value.toRadixString(16).toUpperCase().padLeft(8, '0').substring(2);
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
                  if (val.isNotEmpty && val.length != 6) {
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
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
      hex = hex.replaceAll("#", "");
      if (hex.length == 6) hex = "FF$hex";
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  Widget _radiusSlider(BuildContext context, String title, double value, ValueChanged<double> onChanged, VoidCallback onSave) {
    final theme = Theme.of(context);
    final store = ThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(store.cardRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
              Text("${value.toInt()} px", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
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

    // 规则：开关控制展开/收起；自定义颜色开启时不可选并强制收起
    final bool switchValue = disabled ? false : store.enableThemeMode;
    final bool expanded = switchValue;

    final Color fg = disabled ? tokens.disabledFg : (theme.textTheme.bodyLarge?.color ?? Colors.white);

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

    Widget header = Container(
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
                        disabled ? "已被「自定义颜色」接管" : (store.enableThemeMode ? _modeLabel(store.preferredMode) : "关闭：跟随系统"),
                        style: TextStyle(fontSize: 13, color: disabled ? fg : theme.textTheme.bodyMedium?.color),
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

    Widget bodyCard = Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: bodyRadius),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text("系统 (默认)"),
            value: ThemeMode.system,
            groupValue: store.preferredMode,
            onChanged: disabled ? null : (v) => store.setPreferredMode(v!),
            activeColor: theme.colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // ✅ 回归：2px 背景缝分割（走 tokens）
          Container(height: tokens.dividerThickness, color: tokens.dividerColor),
          RadioListTile<ThemeMode>(
            title: const Text("浅色"),
            value: ThemeMode.light,
            groupValue: store.preferredMode,
            onChanged: disabled ? null : (v) => store.setPreferredMode(v!),
            activeColor: theme.colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Container(height: tokens.dividerThickness, color: tokens.dividerColor),
          RadioListTile<ThemeMode>(
            title: const Text("深色"),
            value: ThemeMode.dark,
            groupValue: store.preferredMode,
            onChanged: disabled ? null : (v) => store.setPreferredMode(v!),
            activeColor: theme.colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );

    Widget expandedBlock = Column(
      children: [
        // ✅ header 与 body 的“背景缝”必须画出来（2px）
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
            ? "#${store.customBackgroundColor!.value.toRadixString(16).toUpperCase().substring(2)}"
            : "默认";
        final cardHex = store.customCardColor != null
            ? "#${store.customCardColor!.value.toRadixString(16).toUpperCase().substring(2)}"
            : "默认";

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FoggyAppBar(
            title: const Text("个性化"),
            isScrolled: _isScrolled,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
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
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          shape: BoxShape.circle,
                        ),
                        child: store.customBackgroundColor == null ? const Icon(Icons.auto_awesome, size: 14, color: Colors.grey) : null,
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
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          shape: BoxShape.circle,
                        ),
                        child: store.customCardColor == null ? const Icon(Icons.auto_awesome, size: 14, color: Colors.grey) : null,
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
              _radiusSlider(context, "全局圆角", store.cardRadius, (val) => store.setCardRadius(val), () => store.savePreferences()),
              const SizedBox(height: 12),
              _radiusSlider(context, "图片圆角", store.imageRadius, (val) => store.setImageRadius(val), () => store.savePreferences()),
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
      if (_sc.offset > 0 && !_isScrolled) setState(() => _isScrolled = true);
      else if (_sc.offset <= 0 && _isScrolled) setState(() => _isScrolled = false);
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  bool _isBuiltInConfig(SourceConfig c) {
    // 约定：默认插件实例 id = default_<pluginId>
    return c.id.startsWith('default_');
  }

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

    // 目前 registry 只有 wallhaven 插件，所以这里先做 wallhaven 风格的“添加实例”
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("添加图源"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "名称 *", hintText: "例如: My Server"),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: "API 地址 *", hintText: "https://..."),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: "用户名 (可选)", hintText: "API 不需要则不填"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(labelText: "API Key (可选)", hintText: "用于认证"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final url = urlCtrl.text.trim();
              if (name.isEmpty || url.isEmpty) return;

              store.addWallhavenSource(
                name: name,
                url: url,
                username: userCtrl.text,
                apiKey: keyCtrl.text,
              );

              Navigator.pop(context);
            },
            child: const Text("添加"),
          ),
        ],
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
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "用户名 (可选)")),
              const SizedBox(height: 16),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: "API Key (可选)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              final nextSettings = Map<String, dynamic>.from(cfg.settings);

              // 默认插件实例：不允许改 name/baseUrl，但允许配 username/apiKey
              if (!builtIn) {
                final n = nameCtrl.text.trim();
                final u = urlCtrl.text.trim();
                if (n.isNotEmpty) {
                  // name 在 SourceConfig 顶层
                }
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
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
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
                        // 当前源标记
                        if (isCurrent) const Icon(Icons.check, size: 18),
                        // 编辑
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditConfigDialog(context, cfg),
                        ),
                        // 删除（默认插件实例不允许删）
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
                    // ✅ 点击行：切换当前源（不再把“切换”和“编辑”绑死）
                    onTap: () => store.setCurrentSourceConfig(cfg.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SettingsGroup(items: [
                SettingsItem(icon: Icons.add_circle_outline, title: "添加新图源", onTap: () => _showAddSourceDialog(context)),
              ]),
            ],
          ),
        );
      },
    );
  }
}