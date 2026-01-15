import 'package:flutter/foundation.dart';
import '../models/wallpaper.dart';

/// 通用分页结果（后面扩展翻页/总数/错误码都方便）
@immutable
class SourceSearchResult {
  final List<Wallpaper> items;
  const SourceSearchResult({required this.items});
}

/// 插件能力（先占位，后面你要做“不同插件不同筛选能力”就靠它）
@immutable
class SourceCapabilities {
  final bool supportsDetail;
  const SourceCapabilities({this.supportsDetail = true});
}

/// 图源插件：定义“怎么请求、怎么解析”
/// - config.settings 里放插件自己的配置（baseUrl/apiKey/...）
/// - filters 先用 wallhaven 的结构（你现有 FilterDrawer），后面再抽象
abstract class SourcePlugin {
  String get pluginId;
  String get defaultName;
  SourceCapabilities get capabilities => const SourceCapabilities();

  /// 生成一个默认配置实例（默认插件实例）
  Map<String, dynamic> defaultSettings();

  /// 拉列表（分页+筛选）
  Future<SourceSearchResult> search({
    required Map<String, dynamic> settings,
    required int page,
    required Map<String, dynamic> filters,
  });

  /// 拉详情（可选）
  Future<WallpaperDetail?> detail({
    required Map<String, dynamic> settings,
    required String id,
  });
}
