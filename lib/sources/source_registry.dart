import 'source_plugin.dart';
import 'wallhaven_source_plugin.dart';
import 'source_plugin.dart';
import 'wallhaven_source_plugin.dart';
import 'simple_json_source_plugin.dart';

class SourceRegistry {
  final Map<String, SourcePlugin> _plugins;
  SourceRegistry._(this._plugins);

  factory SourceRegistry.defaultRegistry() {
    return SourceRegistry._({
      WallhavenSourcePlugin.kId: WallhavenSourcePlugin(),
      SimpleJsonPlugin.kId: SimpleJsonPlugin(), // ✅ 新增
    });
  }

  SourcePlugin plugin(String id) => _plugins[id]!;
  SourcePlugin? tryPlugin(String id) => _plugins[id];

  Iterable<SourcePlugin> get allPlugins => _plugins.values;
}

class SourceRegistry {
  final Map<String, SourcePlugin> _plugins;

  SourceRegistry._(this._plugins);

  factory SourceRegistry.defaultRegistry() {
    return SourceRegistry._({
      WallhavenSourcePlugin.kId: WallhavenSourcePlugin(),
    });
  }

  SourcePlugin? plugin(String pluginId) => _plugins[pluginId];

  SourceConfig defaultConfig() => _plugins[WallhavenSourcePlugin.kId]!.defaultConfig();
}
