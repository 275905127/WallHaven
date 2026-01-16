import 'option_item.dart';
import 'dynamic_filter.dart'; // 确保正确导入

enum SortBy { relevance, newest, views, favorites, random, toplist }
enum SortOrder { asc, desc }

/// 这个是“内容分级”的通用枚举：
/// - safe / questionable / explicit
/// 具体某个源怎么映射（比如 wallhaven purity bitset）是 source 的事
enum RatingLevel { safe, questionable, explicit }

class SourceCapabilities {
  final bool supportsText;

  final bool supportsSort;
  final List<SortBy> sortByOptions;

  final bool supportsOrder;

  final bool supportsResolutions;
  final List<String> resolutionOptions;

  final bool supportsAtleast;
  final List<String> atleastOptions;

  final bool supportsRatios;
  final List<String> ratioOptions;

  final bool supportsColor;
  final List<String> colorOptions;

  final bool supportsRating;
  final List<RatingLevel> ratingOptions;

  final bool supportsCategories;
  final List<OptionItem> categoryOptions;

  final bool supportsTimeRange;
  final List<OptionItem> timeRangeOptions;

  // 新增字段 dynamicFilters
  final List<DynamicFilter> dynamicFilters;

  const SourceCapabilities({
    this.supportsText = true,

    this.supportsSort = false,
    this.sortByOptions = const [],

    this.supportsOrder = false,

    this.supportsResolutions = false,
    this.resolutionOptions = const [],

    this.supportsAtleast = false,
    this.atleastOptions = const [],

    this.supportsRatios = false,
    this.ratioOptions = const [],

    this.supportsColor = false,
    this.colorOptions = const [],

    this.supportsRating = false,
    this.ratingOptions = const [],

    this.supportsCategories = false,
    this.categoryOptions = const [],

    this.supportsTimeRange = false,
    this.timeRangeOptions = const [],

    // 动态过滤器的默认值
    this.dynamicFilters = const [],
  });
}
