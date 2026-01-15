// lib/domain/entities/filter_spec.dart

enum SortOrder { asc, desc }

enum SortBy {
  relevance,
  newest,
  views,
  favorites,
  random,
  toplist, // “意图”存在即可，source 可忽略/降级
}

enum RatingLevel {
  safe,
  questionable,
  explicit,
}

class FilterSpec {
  final String text;

  final SortBy? sortBy;
  final SortOrder? order;

  /// "1920x1080"
  final Set<String> resolutions;

  /// "1920x1080"
  final String? atleast;

  /// "16x9"
  final Set<String> ratios;

  /// hex without '#'
  final String? color;

  /// 通用分级：source 自己映射到 purity/rating/nsfw
  final Set<RatingLevel> rating;

  /// 通用分类：由 source 的 capabilities 提供 options（id/label）
  final Set<String> categories;

  /// 时间窗：由 source 的 capabilities 提供 options（id/label）
  final String? timeRange;

  const FilterSpec({
    this.text = '',
    this.sortBy,
    this.order,
    this.resolutions = const {},
    this.atleast,
    this.ratios = const {},
    this.color,
    this.rating = const {},
    this.categories = const {},
    this.timeRange,
  });

  FilterSpec copyWith({
    String? text,
    SortBy? sortBy,
    SortOrder? order,
    Set<String>? resolutions,
    String? atleast,
    Set<String>? ratios,
    String? color,
    Set<RatingLevel>? rating,
    Set<String>? categories,
    String? timeRange,
  }) {
    return FilterSpec(
      text: text ?? this.text,
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
      resolutions: resolutions ?? this.resolutions,
      atleast: atleast ?? this.atleast,
      ratios: ratios ?? this.ratios,
      color: color ?? this.color,
      rating: rating ?? this.rating,
      categories: categories ?? this.categories,
      timeRange: timeRange ?? this.timeRange,
    );
  }
}