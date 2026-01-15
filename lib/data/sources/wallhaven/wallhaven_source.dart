import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/wallpaper_item.dart';
import '../../http/http_client.dart';
import '../wallpaper_source.dart';

class WallhavenSource implements WallpaperSource {
  @override
  final String sourceId;
  @override
  final String pluginId = 'wallhaven';

  final HttpClient _http;
  final String? apiKey;

  WallhavenSource({
    required this.sourceId,
    required HttpClient http,
    this.apiKey,
  }) : _http = http;

  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    final resp = await _http.dio.get(
      'https://wallhaven.cc/api/v1/search',
      queryParameters: <String, dynamic>{
        'page': query.page,
        ...query.params,
        if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
      },
    );

    final root = resp.data;
    if (root is! Map) return const [];

    final list = (root['data'] as List?) ?? const [];
    final items = <WallpaperItem>[];

    for (final e in list) {
      if (e is! Map) continue;
      final j = e.cast<String, dynamic>();

      final thumbs = (j['thumbs'] as Map?)?.cast<String, dynamic>() ?? const {};
      final id = (j['id'] as String?) ?? '';

      final previewUrl = (thumbs['large'] as String?) ?? (thumbs['small'] as String?) ?? '';
      final smallUrl = (thumbs['small'] as String?) ?? '';
      final originalUrl = (j['path'] as String?) ?? '';

      final w = (j['dimension_x'] is int) ? j['dimension_x'] as int : 0;
      final h = (j['dimension_y'] is int) ? j['dimension_y'] as int : 0;

      items.add(
        WallpaperItem(
          sourceId: sourceId,
          id: id,
          preview: Uri.tryParse(previewUrl) ?? Uri.parse('about:blank'),
          previewSmall: Uri.tryParse(smallUrl),
          original: Uri.tryParse(originalUrl),
          width: w,
          height: h,
          extra: {
            'purity': j['purity'],
            'category': j['category'],
            'ratio': j['ratio'],
            'short_url': j['short_url'],
          },
        ),
      );
    }

    return items;
  }
}
