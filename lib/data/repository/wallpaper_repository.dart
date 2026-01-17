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

  /// ✅ 统一入口：UI 永远调 search()
  /// - pagedSearch：走 source.search
  /// - random：内部多次调用 source.random，凑成“列表”，让首页正常显示
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    if (_source.kind != SourceKind.random) {
      return _source.search(query);
    }

    // random 源没有分页概念，但 UI 需要 page 来触发“加载更多”
    // 这里用 page 影响每次拉取数量：越往后，拉更多，减少“滚动到底加载不到”
    final int count = _randomCountForPage(query.page);

    final List<WallpaperItem> out = [];
    final Set<String> seen = {}; // 用 url 去重（如果 source.id 不是 url 也没关系）

    for (var i = 0; i < count; i++) {
      final item = await _source.random(query.filters);
      if (item == null) continue;

      final key = item.preview.toString();
      if (key.isEmpty) continue;

      if (seen.add(key)) out.add(item);
    }

    return out;
  }

  int _randomCountForPage(int page) {
    // 你现在 grid 是 2 列，按“每页 14~22 张”体感比较像分页源
    // page=1: 16 张；之后每页 +4，上限 28
    final p = page < 1 ? 1 : page;
    final c = 16 + (p - 1) * 4;
    return c.clamp(12, 28);
  }

  Future<WallpaperItem?> random(FilterSpec filters) {
    return _source.random(filters);
  }

  Future<WallpaperDetailItem?> detail(String id) {
    return _source.detail(id);
  }

  SourceKind get kind => _source.kind;
}