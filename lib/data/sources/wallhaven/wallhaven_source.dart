import 'package:dio/dio.dart';

import '../../../domain/entities/filter_spec.dart';
import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/source_capabilities.dart';
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
  final String baseUrl; // 例如：https://wallhaven.cc/api/v1
  final String? apiKey;

  WallhavenSource({
    required this.sourceId,
    required HttpClient http,
    required this.baseUrl,
    this.apiKey,
  }) : _http = http;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
        supportsText: true,
        supportsSort: true,
        sortKeys: ['toplist', 'date_added', 'favorites', 'views', 'random', 'relevance'],
        supportsOrder: true,
        supportsResolutions: true,
        resolutionOptions: [
          '1280x720',
          '1366x768',
          '1600x900',
          '1920x1080',
          '1920x1200',
          '2560x1440',
          '2560x1600',
          '3440x1440',
          '3840x2160',
          '1080x1920',
          '1440x2560',
          '2160x3840',
        ],
        supportsAtleast: true,
        atleastOptions: [
          '',
          '1280x720',
          '1600x900',
          '1920x1080',
          '2560x1440',
          '3440x1440',
          '3840x2160',
          '1080x1920',
          '1440x2560',
          '2160x3840',
        ],
        supportsRatios: true,
        ratioOptions: ['16x9', '16x10', '21x9', '32x9', '4x3', '3x2', '5x4', '1x1', '9x16', '10x16'],
        supportsColor: true,
        colorOptions: [
          '000000',
          '111111',
          '222222',
          '333333',
          '444444',
          '555555',
          '666666',
          '777777',
          '888888',
          '999999',
          'AAAAAA',
          'BBBBBB',
          'CCCCCC',
          'DDDDDD',
          'EEEEEE',
          'FFFFFF',
          '660000',
          '006600',
          '000066',
          '663300',
          '003366',
          '660066',
        ],
        supportsRatings: true,
        ratingOptions: ['sfw', 'sketchy', 'nsfw'],
        supportsCategories: true,
        categoryOptions: ['general', 'anime', 'people'],
        supportsTimeRange: true,
        timeRangeOptions: ['1d', '3d', '1w', '1M', '3M', '6M', '1y'],
      );

  Map<String, dynamic> _buildParams(FilterSpec f) {
    // Wallhaven 的 categories/purity 是 bitset 字符串，这里从通用集合翻译过去。
    // categories: general/anime/people -> 3 bits
    String categoriesBits() {
      final g = f.categories.contains('general') ? '1' : '0';
      final a = f.categories.contains('anime') ? '1' : '0';
      final p = f.categories.contains('people') ? '1' : '0';
      // 如果用户没选任何分类，给 wallhaven 一个“全开”
      if (g == '0' && a == '0' && p == '0') return '111';
      return '$g$a$p';
    }

    // ratings: sfw/sketchy/nsfw -> purity bits
    String purityBits() {
      final s = f.ratings.contains('sfw') ? '1' : '0';
      final k = f.ratings.contains('sketchy') ? '1' : '0';
      final n = f.ratings.contains('nsfw') ? '1' : '0';
      // 如果用户没选任何分级，默认 wallhaven：只开 sfw（更合理）
      if (s == '0' && k == '0' && n == '0') return '100';
      return '$s$k$n';
    }

    final params = <String, dynamic>{
      'sorting': f.sort ?? 'toplist',
      'order': f.order ?? 'desc',
      'categories': categoriesBits(),
      'purity': purityBits(),
      if (f.resolutions.isNotEmpty) 'resolutions': f.resolutions.toList()..sort(),
      if (f.ratios.isNotEmpty) 'ratios': f.ratios.toList()..sort(),
      if ((f.atleast ?? '').trim().isNotEmpty) 'atleast': f.atleast!.trim(),
      if ((f.color ?? '').trim().isNotEmpty) 'colors': f.color!.trim().replaceAll('#', ''),
      if (f.text.trim().isNotEmpty) 'q': f.text.trim(),
      if ((f.sort ?? '') == 'toplist' && (f.timeRange ?? '').trim().isNotEmpty) 'topRange': f.timeRange!.trim(),
    };

    // resolutions/ratios Wallhaven 需要 csv
    if (params['resolutions'] is List<String>) {
      final list = (params['resolutions'] as List<String>);
      params['resolutions'] = list.join(',');
    }
    if (params['ratios'] is List<String>) {
      final list = (params['ratios'] as List<String>);
      params['ratios'] = list.join(',');
    }

    return params;
  }

  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    final resp = await _http.dio.get(
      '$baseUrl/search',
      queryParameters: <String, dynamic>{
        'page': query.page,
        ..._buildParams(query.filters),
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
            'rating': j['purity'],
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
        '$baseUrl/w/$id',
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