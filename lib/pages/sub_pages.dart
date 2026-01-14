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

    // header 的圆角：展开时下方用小圆角接 body
    final BorderRadius headerRadius = BorderRadius.only(
      topLeft: Radius.circular(store.cardRadius),
      topRight: Radius.circular(store.cardRadius),
      bottomLeft: Radius.circular(expanded ? tokens.smallRadius : store.cardRadius),
      bottomRight: Radius.circular(expanded ? tokens.smallRadius : store.cardRadius),
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
                        disabled
                            ? "已被「自定义颜色」接管"
                            : (store.enableThemeMode ? _modeLabel(store.preferredMode) : "关闭：跟随系统"),
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

    Widget body = Container(
      margin: EdgeInsets.only(top: tokens.dividerThickness),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(tokens.smallRadius),
          topRight: Radius.circular(tokens.smallRadius),
          bottomLeft: Radius.circular(store.cardRadius),
          bottomRight: Radius.circular(store.cardRadius),
        ),
      ),
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
          Container(height: 1, color: theme.dividerColor),
          RadioListTile<ThemeMode>(
            title: const Text("浅色"),
            value: ThemeMode.light,
            groupValue: store.preferredMode,
            onChanged: disabled ? null : (v) => store.setPreferredMode(v!),
            activeColor: theme.colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Container(height: 1, color: theme.dividerColor),
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

    return Column(
      children: [
        header,
        AnimatedSize(
          duration: tokens.expandDuration,
          curve: tokens.expandCurve,
          alignment: Alignment.topCenter,
          child: expanded ? body : const SizedBox.shrink(),
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

              // ✅ 颜色模式：折叠收纳（开关=展开，关=收起）；自定义颜色开时禁用并强制收起
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
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
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
              _radiusSlider(context, "卡片圆角", store.cardRadius, (val) => store.setCardRadius(val), () => store.savePreferences()),
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
// 2. 图源管理二级页
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

  void _showAddSourceDialog(BuildContext context) {
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
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "名称 *", hintText: "例如: My Server"), autofocus: true),
              const SizedBox(height: 16),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "API 地址 *", hintText: "https://...")),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "用户名 (可选)", hintText: "API 不需要则不填")),
              const SizedBox(height: 16),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: "API Key (可选)", hintText: "用于认证")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && urlCtrl.text.trim().isNotEmpty) {
                ThemeScope.of(context).addSource(
                  nameCtrl.text,
                  urlCtrl.text,
                  username: userCtrl.text,
                  apiKey: keyCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("添加"),
          ),
        ],
      ),
    );
  }

  void _showEditSourceDialog(BuildContext context, ImageSource source) {
    final nameCtrl = TextEditingController(text: source.name);
    final urlCtrl = TextEditingController(text: source.baseUrl);
    final userCtrl = TextEditingController(text: source.username ?? '');
    final keyCtrl = TextEditingController(text: source.apiKey ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(source.isBuiltIn ? "配置图源 (内置)" : "编辑图源"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "名称", filled: true), enabled: !source.isBuiltIn),
              const SizedBox(height: 16),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "API 地址", filled: true), enabled: !source.isBuiltIn),
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
              ThemeScope.of(context).updateSource(
                source.copyWith(
                  name: source.isBuiltIn ? null : nameCtrl.text,
                  baseUrl: source.isBuiltIn ? null : urlCtrl.text,
                  username: userCtrl.text.trim().isEmpty ? null : userCtrl.text.trim(),
                  apiKey: keyCtrl.text.trim().isEmpty ? null : keyCtrl.text.trim(),
                ),
              );
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
                items: store.sources.map((source) {
                  String subtitle = source.baseUrl;
                  if (source.apiKey != null && source.apiKey!.isNotEmpty) subtitle += "\n🔑 已配置 API Key";

                  return SettingsItem(
                    icon: source.isBuiltIn ? Icons.verified : Icons.link,
                    title: source.name,
                    subtitle: subtitle,
                    trailing: source.isBuiltIn
                        ? const Text("内置", style: TextStyle(fontSize: 12, color: Colors.grey))
                        : IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => store.removeSource(source.id)),
                    onTap: () => _showEditSourceDialog(context, source),
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