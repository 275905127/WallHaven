import '../../domain/search/query_spec.dart';

class WallhavenQueryAdapter {
  static Map<String, dynamic> toParams(QuerySpec q) {
    final params = <String, dynamic>{};

    params['sorting'] = _sortKey(q.sort);
    params['order'] = q.order == SortOrder.desc ? 'desc' : 'asc';
    params['categories'] = _cats(q.categories);
    params['purity'] = _purity(q.ratings);

    if (q.text.trim().isNotEmpty) params['q'] = q.text.trim();
    if (q.resolutions.isNotEmpty) params['resolutions'] = _csv(q.resolutions);
    if (q.ratios.isNotEmpty) params['ratios'] = _csv(q.ratios);
    if (q.atleast.trim().isNotEmpty) params['atleast'] = q.atleast.trim();
    if (q.colorHex.trim().isNotEmpty) params['colors'] = q.colorHex.trim().replaceAll('#', '');

    if (q.sort == SortKey.toplist) params['topRange'] = q.toplistRange;

    return params;
  }

  static String _csv(Set<String> s) => (s.toList()..sort()).join(',');

  static String _sortKey(SortKey k) {
    switch (k) {
      case SortKey.toplist:
        return 'toplist';
      case SortKey.latest:
        return 'date_added';
      case SortKey.favorites:
        return 'favorites';
      case SortKey.views:
        return 'views';
      case SortKey.random:
        return 'random';
      case SortKey.relevance:
        return 'relevance';
    }
  }

  static String _cats(Set<Category> cats) {
    // wallhaven categories: general anime people -> 3 bits
    final g = cats.contains(Category.general) ? '1' : '0';
    final a = cats.contains(Category.anime) ? '1' : '0';
    final p = cats.contains(Category.people) ? '1' : '0';
    return '$g$a$p';
  }

  static String _purity(Set<Rating> r) {
    final s = r.contains(Rating.sfw) ? '1' : '0';
    final k = r.contains(Rating.sketchy) ? '1' : '0';
    final n = r.contains(Rating.nsfw) ? '1' : '0';
    return '$s$k$n';
  }
}
