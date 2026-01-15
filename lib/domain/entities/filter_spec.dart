class FilterSpec {
  final String text;

  /// 通用：排序 key（由 source 定义可用值），例如：
  /// wallhaven: toplist/date_added/favorites/views/random/relevance
  final String? sort;

  /// 通用：升降序（如果 source 支持）
  final String? order; // 'asc' | 'desc'

  /// 通用：精确分辨率列表，例如 ["1920x1080","2560x1440"]
  final Set<String> resolutions;

  /// 通用：至少分辨率，例如 "1920x1080"
  final String? atleast;

  /// 通用：比例列表，例如 ["16x9","21x9"]
  final Set<String> ratios;

  /// 通用：颜色（hex，不带 #），例如 "660000"
  final String? color;

  /// 可选：内容分级（枚举值由 source 自己解释）
  /// wallhaven: "sfw" | "sketchy" | "nsfw"（UI 可以用中文展示，但 value 不动）
  final Set<String> ratings;

  /// 可选：分类（枚举值由 source 自己解释）
  /// wallhaven: "general" | "anime" | "people"
  final Set<String> categories;

  /// 通用：时间范围（某些源的 toplist 才用）
  /// wallhaven: "1d","3d","1w","1M","3M","6M","1y"
  final String? timeRange;

  const FilterSpec({
    this.text = '',
    this.sort,
    this.order,
    this.resolutions = const {},
    this.atleast,
    this.ratios = const {},
    this.color,
    this.ratings = const {},
    this.categories = const {},
    this.timeRange,
  });

  FilterSpec copyWith({
    String? text,
    String? sort,
    String? order,
    Set<String>? resolutions,
    String? atleast,
    Set<String>? ratios,
    String? color,
    Set<String>? ratings,
    Set<String>? categories,
    String? timeRange,
  }) {
    return FilterSpec(
      text: text ?? this.text,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      resolutions: resolutions ?? this.resolutions,
      atleast: atleast ?? this.atleast,
      ratios: ratios ?? this.ratios,
      color: color ?? this.color,
      ratings: ratings ?? this.ratings,
      categories: categories ?? this.categories,
      timeRange: timeRange ?? this.timeRange,
    );
  }
}