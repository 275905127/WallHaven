// lib/sources/source_registry.dart

import 'source_plugin.dart';
import 'wallhaven_source_plugin.dart';
import 'simple_json_source_plugin.dart';

class SourceRegistry {
  final Map<String, SourcePlugin> _plugins;

  SourceRegistry._(this._plugins);

  factory SourceRegistry.defaultRegistry() {
    return SourceRegistry._({
      WallhavenSourcePlugin.kId: WallhavenSourcePlugin(),
      SimpleJsonPlugin.kId: SimpleJsonPlugin(), // generic / 自由 JSON 图源
    });
  }

  /// ThemeStore 需要：可能拿不到 -> 返回 null
  SourcePlugin? plugin(String pluginId) => _plugins[pluginId];

  /// 可选：有的地方你想直接 assert 存在
  SourcePlugin mustPlugin(String pluginId) {
    final p = _plugins[pluginId];
    if (p == null) throw StateError('Plugin not found: $pluginId');
    return p;
  }

  /// 所有插件（用于 UI 展示）
  List<SourcePlugin> get allPlugins => _plugins.values.toList(growable: false);

  /// 所有 pluginId（用于 UI 展示/校验）
  List<String> get allPluginIds => _plugins.keys.toList(growable: false);

  /// ThemeStore 构造默认源：默认用 wallhaven
  SourceConfig defaultConfig() => mustPlugin(WallhavenSourcePlugin.kId).defaultConfig();

  /// ✅ 给 UI/ThemeStore 用：按 pluginId 生成该插件的默认配置
  SourceConfig defaultConfigFor(String pluginId) => mustPlugin(pluginId).defaultConfig();

  /// ✅ 是否支持某个 pluginId（比 plugin()!=null 更语义化）
  bool supports(String pluginId) => _plugins.containsKey(pluginId);
}