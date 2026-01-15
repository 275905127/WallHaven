// lib/domain/entities/filter_spec.dart
enum SortOrder { asc, desc }

enum SortBy {
  relevance,
  newest,
  views,
  favorites,
  random,
  toplist,
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
  final String? color;           // hex without "#"

  final Set<RatingLevel> rating; // safe/questionable/explicit
  final Set<String> categories;  // source-defined ids
  final String? timeRange;       // source-defined id

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