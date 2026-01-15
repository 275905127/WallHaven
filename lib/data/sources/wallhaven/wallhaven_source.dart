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

    final dataList = root['data'];
    if (dataList is! List) return const [];

    final items = <WallpaperItem>[];

    for (final e in dataList) {
      if (e is! Map) continue;
      final j = e.cast<String, dynamic>();

      final id = (j['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) continue;

      final thumbs = (j['thumbs'] as Map?)?.cast<String, dynamic>();
      final thumbLarge = (thumbs?['large'] as String?)?.trim() ?? '';
      final thumbSmall = (thumbs?['small'] as String?)?.trim() ?? '';
      final path = (j['path'] as String?)?.trim() ?? '';

      // ✅ 预览图兜底：large -> small -> path
      final previewUrl = thumbLarge.isNotEmpty
          ? thumbLarge
          : (thumbSmall.isNotEmpty ? thumbSmall : path);

      // 没有任何可用 URL，直接丢弃（不要造 about:blank）
      if (previewUrl.isEmpty) continue;

      final w = _asInt(j['dimension_x']);
      final h = _asInt(j['dimension_y']);

      items.add(
        WallpaperItem(
          sourceId: sourceId,
          id: id,
          preview: Uri.parse(previewUrl),
          previewSmall: thumbSmall.isNotEmpty ? Uri.tryParse(thumbSmall) : null,
          original: path.isNotEmpty ? Uri.tryParse(path) : null,
          width: w,
          height: h,
          extra: <String, dynamic>{
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

      final path = (j['path'] as String?)?.trim() ?? '';
      if (path.isEmpty) return null;

      final w = _asInt(j['dimension_x']);
      final h = _asInt(j['dimension_y']);

      final uploader = (j['uploader'] as Map?)?.cast<String, dynamic>();
      final avatar = (uploader?['avatar'] as Map?)?.cast<String, dynamic>();

      final tags = _parseWallhavenTags(j['tags']);
      final colors = _parseStringList(j['colors']);

      return WallpaperDetailItem(
        sourceId: sourceId,
        id: (j['id'] as String?)?.trim().isNotEmpty == true ? (j['id'] as String).trim() : id,
        image: Uri.parse(path),
        width: w,
        height: h,
        author: (uploader?['username'] as String?)?.trim().isNotEmpty == true ? (uploader?['username'] as String).trim() : null,
        authorAvatar: _bestAvatarUri(avatar),
        shortUrl: Uri.tryParse(((j['short_url'] as String?) ?? '').trim()),
        sourceUrl: Uri.tryParse(((j['source'] as String?) ?? '').trim()),
        views: _asIntOrNull(j['views']),
        favorites: _asIntOrNull(j['favorites']),
        rating: (j['purity'] as String?)?.trim(),
        category: (j['category'] as String?)?.trim(),
        resolution: (j['resolution'] as String?)?.trim(),
        ratio: (j['ratio'] as String?)?.trim(),
        fileSize: _asIntOrNull(j['file_size']),
        fileType: (j['file_type'] as String?)?.trim(),
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

  // ===== helpers =====

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  int? _asIntOrNull(dynamic v) {
    final x = _asInt(v);
    return x == 0 ? null : x;
  }

  List<String> _parseWallhavenTags(dynamic v) {
    final list = <String>[];
    if (v is! List) return list;
    for (final e in v) {
      if (e is Map) {
        final m = e.cast<String, dynamic>();
        final name = (m['name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty) list.add(name);
      }
    }
    return list;
  }

  List<String> _parseStringList(dynamic v) {
    if (v is! List) return const [];
    final out = <String>[];
    for (final e in v) {
      final s = (e?.toString() ?? '').trim();
      if (s.isNotEmpty) out.add(s);
    }
    return out;
  }

  Uri? _bestAvatarUri(Map<String, dynamic>? avatar) {
    if (avatar == null) return null;
    final a200 = (avatar['200px'] as String?)?.trim() ?? '';
    if (a200.isNotEmpty) return Uri.tryParse(a200);
    final a128 = (avatar['128px'] as String?)?.trim() ?? '';
    if (a128.isNotEmpty) return Uri.tryParse(a128);
    return null;
  }
}