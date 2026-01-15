import 'package:dio/dio.dart';
import '../models/wallpaper.dart';
import '../api/wallhaven_api.dart';

/// 插件实例配置（可持久化）
class SourceConfig {
  final String id;       // 实例 id（default_wallhaven / cfg_xxx）
  final String pluginId; // wallhaven / ...
  final String name;     // 展示名
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

/// 统一客户端能力（先满足你现有 UI：列表 + 详情）
/// 未来你要接别的图源，就让那个插件也实现这个接口。
abstract class WallpaperSourceClient {
  Future<List<Wallpaper>> search({
    required int page,
    required Map<String, dynamic> params, // 插件私有参数（当前就是 wallhaven 搜索参数）
  });

  Future<WallpaperDetail?> detail({required String id});
}

/// 插件定义：负责 defaultConfig + 配置清洗 + 生产 client
abstract class SourcePlugin {
  String get pluginId;
  String get defaultName;

  SourceConfig defaultConfig();

  /// 对 settings 做强约束/清洗（避免用户输入导致全站对接失效）
  Map<String, dynamic> sanitizeSettings(Map<String, dynamic> raw);

  /// 由配置生产客户端（可注入 Dio）
  WallpaperSourceClient createClient({
    required Map<String, dynamic> settings,
    Dio? dio,
  });
}

/// Wallhaven 的 client 适配为 WallpaperSourceClient
class WallhavenClientAdapter implements WallpaperSourceClient {
  final WallhavenClient _client;
  WallhavenClientAdapter(this._client);

  @override
  Future<List<Wallpaper>> search({
    required int page,
    required Map<String, dynamic> params,
  }) {
    return _client.search(
      page: page,
      sorting: (params['sorting'] as String?) ?? 'toplist',
      order: (params['order'] as String?) ?? 'desc',
      categories: params['categories'] as String?,
      purity: params['purity'] as String?,
      resolutions: params['resolutions'] as String?,
      ratios: params['ratios'] as String?,
      query: params['q'] as String?,
      atleast: params['atleast'] as String?,
      colors: params['colors'] as String?,
      topRange: params['topRange'] as String?,
    );
  }

  @override
  Future<WallpaperDetail?> detail({required String id}) {
    return _client.detail(id: id);
  }
}
