class SourceCapabilities {
  final bool supportsText;
  final bool supportsSort;
  final List<String> sortKeys;

  final bool supportsOrder;

  final bool supportsResolutions;
  final List<String> resolutionOptions;

  final bool supportsAtleast;
  final List<String> atleastOptions;

  final bool supportsRatios;
  final List<String> ratioOptions;

  final bool supportsColor;
  final List<String> colorOptions;

  final bool supportsRatings;
  final List<String> ratingOptions; // source-defined values

  final bool supportsCategories;
  final List<String> categoryOptions; // source-defined values

  final bool supportsTimeRange;
  final List<String> timeRangeOptions;

  const SourceCapabilities({
    this.supportsText = true,
    this.supportsSort = false,
    this.sortKeys = const [],
    this.supportsOrder = false,
    this.supportsResolutions = false,
    this.resolutionOptions = const [],
    this.supportsAtleast = false,
    this.atleastOptions = const [],
    this.supportsRatios = false,
    this.ratioOptions = const [],
    this.supportsColor = false,
    this.colorOptions = const [],
    this.supportsRatings = false,
    this.ratingOptions = const [],
    this.supportsCategories = false,
    this.categoryOptions = const [],
    this.supportsTimeRange = false,
    this.timeRangeOptions = const [],
  });
}