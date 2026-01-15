import '../../domain/entities/filter_spec.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/source_capabilities.dart';
import '../../domain/entities/source_kind.dart';
import '../../domain/entities/wallpaper_detail_item.dart';
import '../../domain/entities/wallpaper_item.dart';

abstract class WallpaperSource {
  String get sourceId;
  String get pluginId;

  SourceKind get kind;

  SourceCapabilities get capabilities;

  /// 分页搜索源实现这个；随机源可以返回空
  Future<List<WallpaperItem>> search(SearchQuery query);

  /// 随机源实现这个；分页源可以默认返回 null/throw
  Future<WallpaperItem?> random(FilterSpec filters);

  /// 详情（可选）
  Future<WallpaperDetailItem?> detail(String id);
}