// lib/domain/entities/source_capabilities.dart
import 'filter_spec.dart';
import 'option_item.dart';

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
  });
}