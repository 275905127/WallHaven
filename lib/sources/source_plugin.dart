/// lib/sources/source_plugin.dart
///
/// ✅ 目标：彻底把 domain 与 Wallhaven DTO 解耦
/// - SourcePlugin 只负责：defaultConfig + sanitizeSettings + 元信息
/// - 网络请求统一走：data/SourceFactory -> data/sources/*Source -> Repository -> UI
///
/// ⚠️ 这意味着：这里不再 import Dio / Wallpaper / WallhavenClient
library source_plugin;

/// 插件实例配置（可持久化）
class SourceConfig {
  final String id; // 实例 id（default_wallhaven / cfg_xxx）
  final String pluginId; // wallhaven / generic / ...
  final String name; // 展示名
  final Map<String, dynamic> settings;

  const SourceConfig({
    required this.id,
    required this.pluginId,
    required this.name,
    required this.settings,
  });

  SourceConfig copyWith({
    String? name,
    Map<String, dynamic>? settings,
  }) {
    return SourceConfig(
      id: id,
      pluginId: pluginId,
      name: name ?? this.name,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pluginId': pluginId,
        'name': name,
        'settings': settings,
      };

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      id: (json['id'] as String?) ?? '',
      pluginId: (json['pluginId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      settings: (json['settings'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }
}

/// 插件定义：负责 defaultConfig + 配置清洗
abstract class SourcePlugin {
  String get pluginId;
  String get defaultName;

  SourceConfig defaultConfig();

  /// 对 settings 做强约束/清洗（避免用户输入导致全站对接失效）
  Map<String, dynamic> sanitizeSettings(Map<String, dynamic> raw);
}