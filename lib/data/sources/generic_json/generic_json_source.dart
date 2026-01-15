import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/wallpaper_item.dart';
import '../../http/http_client.dart';
import '../wallpaper_source.dart';

class GenericJsonSource implements WallpaperSource {
  @override
  final String sourceId;
  @override
  final String pluginId = 'generic';

  final HttpClient _http;
  final String baseUrl;
  final String searchPath;
  final String? apiKey;

  GenericJsonSource({
    required this.sourceId,
    required HttpClient http,
    required this.baseUrl,
    required this.searchPath,
    this.apiKey,
  }) : _http = http;

  String _join(String base, String path) {
    if (base.isEmpty) return path;
    if (path.isEmpty) return base;
    if (path.startsWith('/')) return '$base$path';
    return '$base/$path';
  }

  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    if (baseUrl.isEmpty) return const [];

    final resp = await _http.dio.get(
      _join(baseUrl, searchPath),
      queryParameters: <String, dynamic>{
        'page': query.page,
        ...query.params,
        if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
      },
    );

    final data = resp.data;
    final list = (data is List)
        ? data
        : (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : const [];

    final items = <WallpaperItem>[];
    for (final e in list) {
      if (e is! Map) continue;
      final j = e.cast<String, dynamic>();

      final id = (j['id'] as String?) ?? '';
      final url = (j['url'] as String?) ?? (j['path'] as String?) ?? '';
      final thumb = (j['thumb'] as String?) ?? (j['preview'] as String?) ?? url;
      final small = (j['small'] as String?) ?? (j['thumb_small'] as String?) ?? '';

      final w = (j['width'] is int) ? j['width'] as int : int.tryParse('${j['width'] ?? ''}') ?? 0;
      final h = (j['height'] is int) ? j['height'] as int : int.tryParse('${j['height'] ?? ''}') ?? 0;

      items.add(
        WallpaperItem(
          sourceId: sourceId,
          id: id,
          preview: Uri.tryParse(thumb) ?? Uri.parse('about:blank'),
          previewSmall: Uri.tryParse(small),
          original: Uri.tryParse(url),
          width: w,
          height: h,
          extra: j,
        ),
      );
    }

    return items;
  }
}
