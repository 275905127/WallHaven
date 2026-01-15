import '../../domain/entities/search_query.dart';
import '../../domain/entities/source_capabilities.dart';
import '../../domain/entities/wallpaper_detail_item.dart';
import '../../domain/entities/wallpaper_item.dart';

abstract class WallpaperSource {
  String get sourceId;
  String get pluginId;

  SourceCapabilities get capabilities;

  Future<List<WallpaperItem>> search(SearchQuery query);

  Future<WallpaperDetailItem?> detail(String id);
}