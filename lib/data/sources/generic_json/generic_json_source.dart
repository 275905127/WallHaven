import 'package:dio/dio.dart';

import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/wallpaper_detail_item.dart';
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
  final String detailPath;
  final String? apiKey;

  GenericJsonSource({
    required this.sourceId,
    required HttpClient http,
    required this.baseUrl,
    required this.searchPath,
    required this.detailPath,
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

  @override
  Future<WallpaperDetailItem?> detail(String id) async {
    if (baseUrl.isEmpty) return null;
    final path = detailPath.replaceAll('{id}', id);

    try {
      final resp = await _http.dio.get(
        _join(baseUrl, path),
        queryParameters: <String, dynamic>{
          if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
        },
      );

      final data = resp.data;
      final Map<String, dynamic>? j = (data is Map && data['data'] is Map)
          ? (data['data'] as Map).cast<String, dynamic>()
          : (data is Map)
              ? data.cast<String, dynamic>()
              : null;

      if (j == null) return null;

      final url = (j['url'] as String?) ?? (j['path'] as String?) ?? '';
      final image = Uri.tryParse(url);
      if (image == null) return null;

      final w = (j['width'] is int) ? j['width'] as int : int.tryParse('${j['width'] ?? ''}') ?? 0;
      final h = (j['height'] is int) ? j['height'] as int : int.tryParse('${j['height'] ?? ''}') ?? 0;

      final tags = (j['tags'] is List)
          ? (j['tags'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : const <String>[];

      final colors = (j['colors'] is List)
          ? (j['colors'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : const <String>[];

      return WallpaperDetailItem(
        sourceId: sourceId,
        id: (j['id'] as String?) ?? id,
        image: image,
        width: w,
        height: h,
        author: (j['uploader'] as String?) ?? (j['author'] as String?),
        shortUrl: Uri.tryParse((j['shortUrl'] as String?) ?? (j['short_url'] as String?) ?? ''),
        sourceUrl: Uri.tryParse((j['source'] as String?) ?? ''),
        views: (j['views'] is int) ? j['views'] as int : int.tryParse('${j['views'] ?? ''}'),
        favorites: (j['favorites'] is int) ? j['favorites'] as int : int.tryParse('${j['favorites'] ?? ''}'),
        category: (j['category'] as String?),
        rating: (j['purity'] as String?) ?? (j['rating'] as String?),
        resolution: (j['resolution'] as String?),
        ratio: (j['ratio'] as String?),
        fileSize: (j['fileSize'] is int) ? j['fileSize'] as int : int.tryParse('${j['fileSize'] ?? ''}'),
        fileType: (j['fileType'] as String?) ?? (j['file_type'] as String?),
        tags: tags,
        colors: colors,
        extra: j,
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}