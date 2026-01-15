// lib/data/sources/wallhaven/wallhaven_source.dart
import 'package:dio/dio.dart';

import '../../../domain/entities/detail_field.dart';
import '../../../domain/entities/filter_spec.dart';
import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/source_capabilities.dart';
import '../../../domain/entities/option_item.dart';
import '../../../domain/entities/source_kind.dart';
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
  final String baseUrl; // e.g. https://wallhaven.cc/api/v1
  final String? apiKey;

  WallhavenSource({
    required this.sourceId,
    required HttpClient http,
    required this.baseUrl,
    this.apiKey,
  }) : _http = http;

  @override
  SourceKind get kind => SourceKind.pagedSearch;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
        supportsText: true,
        supportsSort: true,
        sortByOptions: [
          SortBy.toplist,
          SortBy.newest,
          SortBy.favorites,
          SortBy.views,
          SortBy.random,
          SortBy.relevance,
        ],
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
        ratioOptions: [
          '16x9',
          '16x10',
          '21x9',
          '32x9',
          '4x3',
          '3x2',
          '5x4',
          '1x1',
          '9x16',
          '10x16'
        ],
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
        supportsRating: true,
        ratingOptions: [
          RatingLevel.safe,
          RatingLevel.questionable,
          RatingLevel.explicit
        ],
        supportsCategories: true,
        categoryOptions: [
          OptionItem(id: 'general', label: '常规'),
          OptionItem(id: 'anime', label: '动漫'),
          OptionItem(id: 'people', label: '人物'),
        ],
        supportsTimeRange: true,
        timeRangeOptions: [
          OptionItem(id: '1d', label: '1 天'),
          OptionItem(id: '3d', label: '3 天'),
          OptionItem(id: '1w', label: '1 周'),
          OptionItem(id: '1M', label: '1 月'),
          OptionItem(id: '3M', label: '3 月'),
          OptionItem(id: '6M', label: '6 月'),
          OptionItem(id: '1y', label: '1 年'),
        ],
      );

  Uri _safeUri(String s) => Uri.tryParse(s) ?? Uri.parse('about:blank');

  String _mapSortBy(SortBy v) {
    switch (v) {
      case SortBy.toplist:
        return 'toplist';
      case SortBy.newest:
        return 'date_added';
      case SortBy.views:
        return 'views';
      case SortBy.favorites:
        return 'favorites';
      case SortBy.random:
        return 'random';
      case SortBy.relevance:
        return 'relevance';
    }
  }

  String _mapOrder(SortOrder o) => o == SortOrder.asc ? 'asc' : 'desc';

  // Wallhaven: categories/purity 都是 bitset
  String _mapCategories(Set<String> cats) {
    // ids: general/anime/people
    final g = cats.contains('general') ? '1' : '0';
    final a = cats.contains('anime') ? '1' : '0';
    final p = cats.contains('people') ? '1' : '0';

    final s = '$g$a$p';
    return (s == '000') ? '111' : s; // 空 -> 不限制
  }

  String _mapPurity(Set<RatingLevel> r) {
    // safe/questionable/explicit -> sfw/sketchy/nsfw
    final sfw = r.contains(RatingLevel.safe) ? '1' : '0';
    final sk = r.contains(RatingLevel.questionable) ? '1' : '0';
    final ns = r.contains(RatingLevel.explicit) ? '1' : '0';

    final s = '$sfw$sk$ns';
    return (s == '000') ? '100' : s; // 空 -> 只安全（默认）
  }

  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    final f = query.filters;

    final qp = <String, dynamic>{
      'page': query.page,
      if (f.text.trim().isNotEmpty) 'q': f.text.trim(),
      if (f.sortBy != null) 'sorting': _mapSortBy(f.sortBy!),
      if (f.order != null) 'order': _mapOrder(f.order!),
      if (f.resolutions.isNotEmpty)
        'resolutions': (f.resolutions.toList()..sort()).join(','),
      if ((f.atleast ?? '').trim().isNotEmpty) 'atleast': f.atleast!.trim(),
      if (f.ratios.isNotEmpty) 'ratios': (f.ratios.toList()..sort()).join(','),
      if ((f.color ?? '').trim().isNotEmpty)
        'colors': f.color!.trim().replaceAll('#', ''),
      // categories/rating/timeRange：wallhaven 专属映射，但输入仍是通用
      'categories': _mapCategories(f.categories),
      'purity': _mapPurity(f.rating),
      if ((f.timeRange ?? '').trim().isNotEmpty) 'topRange': f.timeRange!.trim(),
      if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
    };

    final resp = await _http.dio.get('$baseUrl/search', queryParameters: qp);
    final root = resp.data;
    if (root is! Map) return const [];

    final list = (root['data'] as List?) ?? const [];
    final items = <WallpaperItem>[];

    for (final e in list) {
      if (e is! Map) continue;
      final j = e.cast<String, dynamic>();

      final thumbs = (j['thumbs'] as Map?)?.cast<String, dynamic>() ?? const {};
      final id = (j['id'] as String?) ?? '';
      if (id.isEmpty) continue;

      final previewUrl =
          (thumbs['large'] as String?) ?? (thumbs['small'] as String?) ?? '';
      final smallUrl = (thumbs['small'] as String?) ?? '';
      final originalUrl = (j['path'] as String?) ?? '';

      final w = (j['dimension_x'] is int) ? j['dimension_x'] as int : 0;
      final h = (j['dimension_y'] is int) ? j['dimension_y'] as int : 0;

      if (previewUrl.isEmpty) continue;

      items.add(
        WallpaperItem(
          sourceId: sourceId,
          id: id,
          preview: _safeUri(previewUrl),
          previewSmall: smallUrl.isNotEmpty ? Uri.tryParse(smallUrl) : null,
          original: originalUrl.isNotEmpty ? Uri.tryParse(originalUrl) : null,
          width: w,
          height: h,
          extra: j,
        ),
      );
    }

    return items;
  }

  /// ✅ 关键：Wallhaven 不是随机源，这里直接返回 null
  @override
  Future<WallpaperItem?> random(FilterSpec filters) async => null;

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

      final path = (j['path'] as String?) ?? '';
      if (path.isEmpty) return null;

      final w = (j['dimension_x'] is int) ? j['dimension_x'] as int : 0;
      final h = (j['dimension_y'] is int) ? j['dimension_y'] as int : 0;

      final uploader = (j['uploader'] as Map?)?.cast<String, dynamic>();
      final avatar = (uploader?['avatar'] as Map?)?.cast<String, dynamic>();

      final tags = <String>[];
      final tagsJson = (j['tags'] as List?) ?? const [];
      for (final t in tagsJson) {
        if (t is Map) {
          final name = (t as Map).cast<String, dynamic>()['name'];
          if (name is String && name.trim().isNotEmpty) tags.add(name.trim());
        }
      }

      final colors = <String>[];
      final colorsJson = (j['colors'] as List?) ?? const [];
      for (final c in colorsJson) {
        final s = c?.toString().trim() ?? '';
        if (s.isNotEmpty) colors.add(s);
      }

      final fields = <DetailField>[];

      void add(String key, String label, dynamic v) {
        final s = v?.toString().trim() ?? '';
        if (s.isEmpty) return;
        fields.add(DetailField(key: key, label: label, value: s));
      }

      add('author', '上传者', uploader?['username']);
      add('short_url', '短链', j['short_url']);
      add('views', '浏览量', j['views']);
      add('favorites', '收藏量', j['favorites']);
      add('resolution', '分辨率', j['resolution'] ?? (w > 0 && h > 0 ? '${w}x$h' : null));
      add('file_size', '大小', j['file_size']);
      add('file_type', '格式', j['file_type']);
      add('category', '分类', j['category']);
      add('purity', '分级', j['purity']);
      add('source', '来源', j['source']);

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
        resolution: (j['resolution'] as String?),
        ratio: (j['ratio'] as String?),
        fileSize: (j['file_size'] as int?),
        fileType: (j['file_type'] as String?),
        tags: tags,
        colors: colors,
        fields: fields,
        extra: j,
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}