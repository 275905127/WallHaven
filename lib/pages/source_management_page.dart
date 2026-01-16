// lib/pages/source_management_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../sources/source_plugin.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';
import '../widgets/settings_widgets.dart';

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
      final scrolled = _sc.offset > 0;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
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
                          Expanded(child: Text(errorText!, style: const TextStyle(color: Colors.red))),
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
                                      jsonCtrl.text = const JsonEncoder.withIndent("  ").convert(sample);
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