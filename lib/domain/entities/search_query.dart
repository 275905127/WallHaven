class SearchQuery {
  final int page;
  final Map<String, dynamic> params;

  const SearchQuery({
    required this.page,
    this.params = const {},
  });
}
