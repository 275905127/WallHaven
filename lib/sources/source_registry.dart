import 'source_plugin.dart';
import 'wallhaven_source_plugin.dart';

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
