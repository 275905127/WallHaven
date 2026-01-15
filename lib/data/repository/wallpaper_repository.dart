import '../../domain/entities/filter_spec.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/source_kind.dart';
import '../../domain/entities/wallpaper_detail_item.dart';
import '../../domain/entities/wallpaper_item.dart';
import '../sources/wallpaper_source.dart';

class WallpaperRepository {
  WallpaperSource _source;

  WallpaperRepository(this._source);

  WallpaperSource get source => _source;

  void setSource(WallpaperSource next) {
    _source = next;
  }

  Future<List<WallpaperItem>> search(SearchQuery query) {
    return _source.search(query);
  }

  Future<WallpaperItem?> random(FilterSpec filters) {
    return _source.random(filters);
  }

  Future<WallpaperDetailItem?> detail(String id) {
    return _source.detail(id);
  }

  SourceKind get kind => _source.kind;
}