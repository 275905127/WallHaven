import 'filter_spec.dart';

class SearchQuery {
  final int page;
  final FilterSpec filters;

  const SearchQuery({
    required this.page,
    required this.filters,
  });
}