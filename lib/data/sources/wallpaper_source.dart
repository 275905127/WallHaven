import '../../domain/entities/filter_spec.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/source_capabilities.dart';
import '../../domain/entities/source_kind.dart';
import '../../domain/entities/wallpaper_detail_item.dart';
import '../../domain/entities/wallpaper_item.dart';

/// 冻结接口：任何 source 都必须实现这三个方法（不支持就返回空/null）
/// - search: 分页搜索源返回列表；随机源返回空列表
/// - random: 随机源返回单个；分页源返回 null
/// - detail: 可选，不支持返回 null
abstract class WallpaperSource {
  String get sourceId;
  String get pluginId;

  SourceKind get kind;

  SourceCapabilities get capabilities;

  Future<List<WallpaperItem>> search(SearchQuery query);

  Future<WallpaperItem?> random(FilterSpec filters);

  Future<WallpaperDetailItem?> detail(String id);
}