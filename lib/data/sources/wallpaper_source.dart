import '../../domain/entities/search_query.dart';
import '../../domain/entities/wallpaper_detail_item.dart';
import '../../domain/entities/wallpaper_item.dart';

abstract class WallpaperSource {
  String get sourceId; // SourceConfig.id
  String get pluginId; // wallhaven / generic / ...

  Future<List<WallpaperItem>> search(SearchQuery query);

  Future<WallpaperDetailItem?> detail(String id);
}