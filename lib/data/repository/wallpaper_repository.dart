import '../../domain/entities/search_query.dart';
import '../../domain/entities/wallpaper_detail_item.dart';
import '../../domain/entities/wallpaper_item.dart';
import '../sources/wallpaper_source.dart';

class WallpaperRepository {
  WallpaperSource _source;

  WallpaperRepository(this._source);

  String get sourceId => _source.sourceId;
  String get pluginId => _source.pluginId;

  void setSource(WallpaperSource source) {
    _source = source;
  }

  Future<List<WallpaperItem>> search(SearchQuery query) {
    return _source.search(query);
  }

  Future<WallpaperDetailItem?> detail(String id) {
    return _source.detail(id);
  }
}