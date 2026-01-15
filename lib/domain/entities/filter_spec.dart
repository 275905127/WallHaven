// lib/domain/entities/filter_spec.dart
enum SortOrder { asc, desc }

enum SortBy {
  relevance,
  newest,
  views,
  favorites,
  random,
  toplist, // 允许存在，但只是“意图”，source 可选择忽略
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

  final Set<String> resolutions; // "1920x1080"
  final String? atleast;         // "1920x1080"
  final Set<String> ratios;      // "16x9"
  final String? color;           // hex without #

  // 通用：内容等级（source 自己映射到 purity / rating / nsfw）
  final Set<RatingLevel> rating;

  // 通用：分类维度（source 自己给 options，UI 只显示 label）
  final Set<String> categories;

  // 通用：时间范围（如果 source 支持榜单/热门时间窗）
  final String? timeRange; // 仍是字符串，但值由 source 的能力定义

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