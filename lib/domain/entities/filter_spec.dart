import 'source_capabilities.dart';

class FilterSpec {
  final String text;

  final SortBy? sortBy;
  final SortOrder? order;

  final Set<String> resolutions;
  final String? atleast;
  final Set<String> ratios;

  final String? color;

  final Set<RatingLevel> rating;
  final Set<String> categories;

  final String? timeRange;

  /// ✅ 自定义参数（给随机源/第三方源用）
  /// key = paramName, value = 具体值（字符串）
  final Map<String, String> extras;

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
    this.extras = const {},
  });

  FilterSpec copyWith({
    String? text,
    SortBy? sortBy,
    bool clearSortBy = false,
    SortOrder? order,
    bool clearOrder = false,
    Set<String>? resolutions,
    String? atleast,
    bool clearAtleast = false,
    Set<String>? ratios,
    String? color,
    bool clearColor = false,
    Set<RatingLevel>? rating,
    Set<String>? categories,
    String? timeRange,
    bool clearTimeRange = false,
    Map<String, String>? extras,
  }) {
    return FilterSpec(
      text: text ?? this.text,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      order: clearOrder ? null : (order ?? this.order),
      resolutions: resolutions ?? this.resolutions,
      atleast: clearAtleast ? null : (atleast ?? this.atleast),
      ratios: ratios ?? this.ratios,
      color: clearColor ? null : (color ?? this.color),
      rating: rating ?? this.rating,
      categories: categories ?? this.categories,
      timeRange: clearTimeRange ? null : (timeRange ?? this.timeRange),
      extras: extras ?? this.extras,
    );
  }

  FilterSpec putExtra(String key, String value) {
    final k = key.trim();
    if (k.isEmpty) return this;
    final next = Map<String, String>.from(extras);
    next[k] = value;
    return copyWith(extras: next);
  }

  FilterSpec removeExtra(String key) {
    final k = key.trim();
    if (k.isEmpty) return this;
    if (!extras.containsKey(k)) return this;
    final next = Map<String, String>.from(extras)..remove(k);
    return copyWith(extras: next);
  }
}