// lib/data/sources/wallpaper_source.dart
import '../../domain/entities/search_query.dart';
import '../../domain/entities/source_capabilities.dart';
import '../../domain/entities/wallpaper_detail_item.dart';
import '../../domain/entities/wallpaper_item.dart';

abstract class WallpaperSource {
  String get sourceId;   // SourceConfig.id
  String get pluginId;   // wallhaven / generic / ...

  /// ✅ UI 动态渲染筛选项的依据
  SourceCapabilities get capabilities;

  Future<List<WallpaperItem>> search(SearchQuery query);
  Future<WallpaperDetailItem?> detail(String id);
}