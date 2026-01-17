// lib/pages/source_management_page.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/http/http_client.dart';
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

  // ✅ 专门给“测试图源”用的 HTTP 客户端（避免污染业务链路）
  final HttpClient _probeHttp = HttpClient();

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
    _probeHttp.dio.close(force: true);
    super.dispose();
  }

  bool _isBuiltInConfig(SourceConfig c) => c.id.startsWith('default_');

  String _baseUrlOf(SourceConfig c) {
    final v = c.settings['baseUrl'];
    return (v is String) ? v.trim() : '';
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

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =========================
  // ✅ Probe helpers (只用于测试)
  // =========================
  String _trimSlash(String s) {
    var u = s.trim();
    while (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  String _join(String base, String path) {
    final b = _trimSlash(base);
    final p = path.trim();
    if (p.isEmpty) return b;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '$b$p';
    return '$b/$p';
  }

  String _normWallhavenApiBase(String raw) {
    var u = raw.trim();
    if (u.isEmpty) u = 'https://wallhaven.cc/api/v1';

    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    u = _trimSlash(u);

    // 允许用户填：wallhaven.cc / wallhaven.cc/api / wallhaven.cc/api/v1
    if (u.endsWith('/api/v1')) return u;
    if (u.endsWith('/api')) return '$u/v1';

    final uri = Uri.tryParse(u);
    final host = uri?.host.toLowerCase() ?? '';
    if (host.contains('wallhaven.cc') && !u.endsWith('/api/v1')) {
      return '$u/api/v1';
    }

    // 非 wallhaven 域名就不瞎补
    return u;
  }

  String? _extractUrl(dynamic x) {
    if (x is String) {
      final s = x.trim();
      return s.isEmpty ? null : s;
    }
    if (x is Map) {
      for (final k in const ['url', 'image', 'src', 'path', 'link', 'data']) {
        final v = x[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return null;
  }

  dynamic _pickPayload(dynamic root, String listKey) {
    if (listKey.isEmpty || listKey == '@direct') return root;
    if (root is Map && root.containsKey(listKey)) return root[listKey];
    return root;
  }

  Future<Map<String, dynamic>> _probeWallhaven(SourceConfig cfg) async {
    final apiBase = _normWallhavenApiBase(_baseUrlOf(cfg));
    final apiKey = _apiKeyOf(cfg);

    // 最小探测：/search?page=1
    final url = _join(apiBase, '/search');

    final qp = <String, dynamic>{
      'page': 1,
      // 不给 purity/categories 时 Wallhaven 也能回，但结果可能受默认值影响
      if (apiKey != null && apiKey.isNotEmpty) 'apikey': apiKey,
    };

    final resp = await _probeHttp.dio.get(url, queryParameters: qp);

    final data = resp.data;
    if (data is! Map) {
      return {
        'ok': false,
        'status': resp.statusCode ?? -1,
        'message': '返回不是 JSON object',
      };
    }

    final list = (data['data'] as List?) ?? const [];
    final count = list.length;

    String? firstThumb;
    if (count > 0) {
      final e = list.first;
      if (e is Map) {
        final thumbs = (e['thumbs'] as Map?) ?? const {};
        firstThumb = (thumbs['large'] as String?) ??
            (thumbs['small'] as String?) ??
            (e['path'] as String?);
      }
    }

    return {
      'ok': resp.statusCode == 200,
      'status': resp.statusCode ?? -1,
      'count': count,
      'sample': firstThumb,
      'url': url,
    };
  }

  Future<Map<String, dynamic>> _probeGeneric(SourceConfig cfg) async {
    final baseUrl = _baseUrlOf(cfg);
    final apiKey = _apiKeyOf(cfg);

    final searchPath = (cfg.settings['searchPath'] is String) ? (cfg.settings['searchPath'] as String).trim() : '';
    final listKey = (cfg.settings['listKey'] is String) ? (cfg.settings['listKey'] as String).trim() : '';

    if (baseUrl.isEmpty) {
      return {'ok': false, 'status': -1, 'message': 'baseUrl 为空'};
    }

    // generic 可能 baseUrl 就是完整 endpoint；searchPath 可能为空
    final url = _join(baseUrl, searchPath);

    final qp = <String, dynamic>{
      // 不加 page/q，尽量不假设接口
      if (apiKey != null && apiKey.isNotEmpty) 'apikey': apiKey,
    };

    final resp = await _probeHttp.dio.get(url, queryParameters: qp);
    final root = resp.data;

    // 尝试给用户一个“我确实拿到图了”的证据：抽一个 url
    String? extracted;

    if (listKey == '@direct') {
      extracted = _extractUrl(root) ?? _extractUrl(_pickPayload(root, listKey));
    } else {
      final payload = _pickPayload(root, listKey);
      extracted = _extractUrl(payload);
      if (extracted == null && payload is List && payload.isNotEmpty) {
        extracted = _extractUrl(payload.first);
      }
      if (extracted == null && root is Map) {
        // 常见：dataKey / data
        final dataKey = (cfg.settings['dataKey'] ?? cfg.settings['listKey'] ?? 'data').toString().trim();
        final p = root[dataKey];
        extracted = _extractUrl(p);
        if (extracted == null && p is List && p.isNotEmpty) {
          extracted = _extractUrl(p.first);
        }
      }
    }

    return {
      'ok': resp.statusCode == 200,
      'status': resp.statusCode ?? -1,
      'url': url,
      'sample': extracted,
      'note': extracted == null ? '没能从响应里提取到直链（但不一定代表配置错，可能字段名不同）' : null,
    };
  }

  Future<void> _probeSource(SourceConfig cfg) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        title: Text('测试图源'),
        content: SizedBox(
          height: 72,
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 14),
              Expanded(child: Text('正在请求接口…')),
            ],
          ),
        ),
      ),
    );

    Map<String, dynamic> result;
    try {
      final pluginId = cfg.pluginId.trim();
      if (pluginId == 'wallhaven') {
        result = await _probeWallhaven(cfg);
      } else if (pluginId == 'generic') {
        result = await _probeGeneric(cfg);
      } else {
        result = {
          'ok': false,
          'status': -1,
          'message': '不支持测试的 pluginId: $pluginId',
        };
      }
    } on DioException catch (e) {
      result = {
        'ok': false,
        'status': e.response?.statusCode ?? -1,
        'message': e.message ?? 'DioException',
        'detail': e.response?.data,
      };
    } catch (e) {
      result = {
        'ok': false,
        'status': -1,
        'message': '异常：$e',
      };
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading

    final ok = result['ok'] == true;

    showDialog(
      context: context,
      builder: (ctx) {
        final status = result['status'];
        final url = (result['url']?.toString() ?? '').trim();
        final msg = (result['message']?.toString() ?? '').trim();
        final count = result['count'];
        final sample = (result['sample']?.toString() ?? '').trim();
        final note = (result['note']?.toString() ?? '').trim();

        String summary = ok ? '✅ 连接成功' : '❌ 连接失败';
        if (status != null) summary += '（HTTP: $status）';

        final lines = <String>[
          if (url.isNotEmpty) '请求：$url',
          if (count != null) '返回数量：$count',
          if (sample.isNotEmpty) '示例：$sample',
          if (note.isNotEmpty) '说明：$note',
          if (msg.isNotEmpty) '错误：$msg',
        ];

        return AlertDialog(
          title: Text(summary),
          content: SingleChildScrollView(
            child: SelectableText(lines.isEmpty ? '无更多信息' : lines.join('\n\n')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
            if (sample.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _toast('已拿到示例直链（你可以复制去浏览器验证）');
                },
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }

  // =========================
  // Add / Edit dialogs
  // =========================
  void _showAddSourceDialog(BuildContext context) {
    final store = ThemeScope.of(context);

    final jsonCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final listKeyCtrl = TextEditingController(text: "@direct");

    String? errorText;

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
                        _toast("已添加图源");
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
                      _toast("已添加图源");
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

                        // ✅ 新增：测试按钮（不影响当前源，不切换也能测）
                        IconButton(
                          tooltip: "测试图源",
                          icon: const Icon(Icons.bolt_outlined),
                          onPressed: () => _probeSource(cfg),
                        ),

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