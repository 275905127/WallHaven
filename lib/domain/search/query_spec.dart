enum SortKey { toplist, latest, favorites, views, random, relevance }

enum SortOrder { desc, asc }

enum Category { general, anime, people }

enum Rating { sfw, sketchy, nsfw }

class QuerySpec {
  final String text;

  final SortKey sort;
  final SortOrder order;

  final Set<Category> categories;
  final Set<Rating> ratings;

  final Set<String> resolutions; // "1920x1080"
  final Set<String> ratios; // "16x9"
  final String atleast; // "1920x1080" or ""
  final String colorHex; // "660000" or ""

  /// 只在 toplist 时生效：1d/3d/1w/1M/3M/6M/1y
  final String toplistRange;

  const QuerySpec({
    this.text = '',
    this.sort = SortKey.toplist,
    this.order = SortOrder.desc,
    this.categories = const {Category.general, Category.anime, Category.people},
    this.ratings = const {Rating.sfw},
    this.resolutions = const {},
    this.ratios = const {},
    this.atleast = '',
    this.colorHex = '',
    this.toplistRange = '1M',
  });

  QuerySpec copyWith({
    String? text,
    SortKey? sort,
    SortOrder? order,
    Set<Category>? categories,
    Set<Rating>? ratings,
    Set<String>? resolutions,
    Set<String>? ratios,
    String? atleast,
    String? colorHex,
    String? toplistRange,
  }) {
    return QuerySpec(
      text: text ?? this.text,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      categories: categories ?? this.categories,
      ratings: ratings ?? this.ratings,
      resolutions: resolutions ?? this.resolutions,
      ratios: ratios ?? this.ratios,
      atleast: atleast ?? this.atleast,
      colorHex: colorHex ?? this.colorHex,
      toplistRange: toplistRange ?? this.toplistRange,
    );
  }
}
