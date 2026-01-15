import 'dynamic_filter.dart';
import 'option_item.dart';

enum SortBy { toplist, newest, favorites, views, random, relevance }
enum SortOrder { asc, desc }
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

  /// ✅ 自定义筛选（第三方源：isNsfw/type/imageType 这种）
  final List<DynamicFilter> dynamicFilters;

  const SourceCapabilities({
    required this.supportsText,

    required this.supportsSort,
    this.sortByOptions = const [],

    required this.supportsOrder,

    required this.supportsResolutions,
    this.resolutionOptions = const [],

    required this.supportsAtleast,
    this.atleastOptions = const [],

    required this.supportsRatios,
    this.ratioOptions = const [],

    required this.supportsColor,
    this.colorOptions = const [],

    required this.supportsRating,
    this.ratingOptions = const [],

    required this.supportsCategories,
    this.categoryOptions = const [],

    required this.supportsTimeRange,
    this.timeRangeOptions = const [],

    this.dynamicFilters = const [],
  });

  static const minimal = SourceCapabilities(
    supportsText: true,
    supportsSort: false,
    supportsOrder: false,
    supportsResolutions: false,
    supportsAtleast: false,
    supportsRatios: false,
    supportsColor: false,
    supportsRating: false,
    supportsCategories: false,
    supportsTimeRange: false,
  );
}