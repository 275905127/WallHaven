import 'package:dio/dio.dart';

import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/wallpaper_detail_item.dart';
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

  @override
  Future<WallpaperDetailItem?> detail(String id) async {
    try {
      final resp = await _http.dio.get(
        'https://wallhaven.cc/api/v1/w/$id',
        queryParameters: <String, dynamic>{
          if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
        },
      );

      final root = resp.data;
      if (root is! Map) return null;

      final data = root['data'];
      if (data is! Map) return null;

      final j = data.cast<String, dynamic>();

      final uploader = (j['uploader'] as Map?)?.cast<String, dynamic>();
      final avatar = (uploader?['avatar'] as Map?)?.cast<String, dynamic>();

      final tagsJson = (j['tags'] as List?) ?? const [];
      final tags = <String>[];
      for (final t in tagsJson) {
        if (t is Map) {
          final name = (t as Map).cast<String, dynamic>()['name'];
          if (name is String && name.trim().isNotEmpty) tags.add(name);
        }
      }

      final colorsJson = (j['colors'] as List?) ?? const [];
      final colors = colorsJson.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();

      final path = (j['path'] as String?) ?? '';
      if (path.isEmpty) return null;

      final w = (j['dimension_x'] is int) ? j['dimension_x'] as int : 0;
      final h = (j['dimension_y'] is int) ? j['dimension_y'] as int : 0;

      return WallpaperDetailItem(
        sourceId: sourceId,
        id: (j['id'] as String?) ?? id,
        image: Uri.parse(path),
        width: w,
        height: h,
        author: (uploader?['username'] as String?),
        authorAvatar: Uri.tryParse((avatar?['200px'] as String?) ?? (avatar?['128px'] as String?) ?? ''),
        shortUrl: Uri.tryParse((j['short_url'] as String?) ?? ''),
        sourceUrl: Uri.tryParse((j['source'] as String?) ?? ''),
        views: (j['views'] as int?),
        favorites: (j['favorites'] as int?),
        rating: (j['purity'] as String?),
        category: (j['category'] as String?),
        resolution: (j['resolution'] as String?),
        ratio: (j['ratio'] as String?),
        fileSize: (j['file_size'] as int?),
        fileType: (j['file_type'] as String?),
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