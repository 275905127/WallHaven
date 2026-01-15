import 'source_plugin.dart';
import 'wallhaven_source_plugin.dart';

class SourceRegistry {
  final Map<String, SourcePlugin> _plugins;

  SourceRegistry._(this._plugins);

  factory SourceRegistry.defaultRegistry() {
    final plugins = <String, SourcePlugin>{
      WallhavenSourcePlugin.kId: WallhavenSourcePlugin(),
    };
    return SourceRegistry._(plugins);
  }

  SourcePlugin? plugin(String pluginId) => _plugins[pluginId];

  /// 默认插件 id（你以后想改默认源，只改这里）
  String get defaultPluginId => WallhavenSourcePlugin.kId;
}
