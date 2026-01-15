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
      SimpleJsonPlugin.kId: SimpleJsonPlugin(), // ✅ generic / 自由 JSON 图源
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

  Iterable<SourcePlugin> get allPlugins => _plugins.values;

  /// ThemeStore 构造默认源：默认用 wallhaven
  SourceConfig defaultConfig() => mustPlugin(WallhavenSourcePlugin.kId).defaultConfig();
}