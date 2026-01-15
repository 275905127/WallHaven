// lib/data/sources/wallhaven/wallhaven_source.dart
import 'package:dio/dio.dart';

import '../../../domain/entities/detail_field.dart';
import '../../../domain/entities/filter_spec.dart';
import '../../../domain/entities/option_item.dart';
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
  final String baseUrl; // e.g. https://wallhaven.cc/api/v1
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
          '10x16',
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
        ratingOptions: [RatingLevel.safe, RatingLevel.questionable, RatingLevel.explicit],
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

  String _wallhavenSorting(SortBy? v) {
    switch (v) {
      case SortBy.newest:
        return 'date_added';
      case SortBy.relevance:
        return 'relevance';
      case SortBy.random:
        return 'random';
      case SortBy.views:
        return 'views';
      case SortBy.favorites:
        return 'favorites';
      case SortBy.toplist:
      default:
        return 'toplist';
    }
  }

  String _wallhavenOrder(SortOrder? v) {
    switch (v) {
      case SortOrder.asc:
        return 'asc';
      case SortOrder.desc:
      default:
        return 'desc';
    }
  }

  // categories: general/anime/people -> 3 bits
  String _categoriesBits(Set<String> cats) {
    final g = cats.contains('general') ? '1' : '0';
    final a = cats.contains('anime') ? '1' : '0';
    final p = cats.contains('people') ? '1' : '0';
    if (g == '0' && a == '0' && p == '0') return '111'; // 没选就全开
    return '$g$a$p';
  }

  // purity: sfw/sketchy/nsfw -> 3 bits (safe/questionable/explicit)
  String _purityBits(Set<RatingLevel> rating) {
    final s = rating.contains(RatingLevel.safe) ? '1' : '0';
    final k = rating.contains(RatingLevel.questionable) ? '1' : '0';
    final n = rating.contains(RatingLevel.explicit) ? '1' : '0';
    if (s == '0' && k == '0' && n == '0') return '100'; // 没选默认安全
    return '$s$k$n';
  }

  Map<String, dynamic> _buildParams(FilterSpec f) {
    final sorting = _wallhavenSorting(f.sortBy);
    final params = <String, dynamic>{
      'sorting': sorting,
      'order': _wallhavenOrder(f.order),
      'categories': _categoriesBits(f.categories),
      'purity': _purityBits(f.rating),
      if (f.resolutions.isNotEmpty) 'resolutions': (f.resolutions.toList()..sort()).join(','),
      if (f.ratios.isNotEmpty) 'ratios': (f.ratios.toList()..sort()).join(','),
      if ((f.atleast ?? '').trim().isNotEmpty) 'atleast': f.atleast!.trim(),
      if ((f.color ?? '').trim().isNotEmpty) 'colors': f.color!.trim().replaceAll('#', ''),
      if (f.text.trim().isNotEmpty) 'q': f.text.trim(),
      if (sorting == 'toplist' && (f.timeRange ?? '').trim().isNotEmpty) 'topRange': f.timeRange!.trim(),
    };
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
          extra: j,
        ),
      );
    }

    return items;
  }

  String _humanSize(int bytes) {
    if (bytes <= 0) return '-';
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;
    final b = bytes.toDouble();
    if (b >= gb) return '${(b / gb).toStringAsFixed(2)} GB';
    if (b >= mb) return '${(b / mb).toStringAsFixed(2)} MB';
    if (b >= kb) return '${(b / kb).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  String _labelCategory(String? v) {
    switch (v) {
      case 'general':
        return '常规';
      case 'anime':
        return '动漫';
      case 'people':
        return '人物';
      default:
        return v?.toString() ?? '-';
    }
  }

  String _labelPurity(String? v) {
    switch (v) {
      case 'sfw':
        return '安全';
      case 'sketchy':
        return '擦边';
      case 'nsfw':
        return '限制';
      default:
        return v?.toString() ?? '-';
    }
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

      final shortUrl = Uri.tryParse((j['short_url'] as String?) ?? '');
      final sourceUrl = Uri.tryParse((j['source'] as String?) ?? '');

      final purity = (j['purity'] as String?);
      final category = (j['category'] as String?);
      final views = j['views'] as int?;
      final fav = j['favorites'] as int?;
      final resolution = (j['resolution'] as String?);
      final ratio = (j['ratio'] as String?);
      final fileSize = j['file_size'] as int?;
      final fileType = j['file_type'] as String?;

      // ✅ fields：UI 只渲染，不再解释语义
      final fields = <DetailField>[
        if ((uploader?['username'] as String?)?.isNotEmpty == true)
          DetailField(key: 'author', label: '上传者', value: (uploader?['username'] as String)),
        if ((shortUrl?.toString() ?? '').isNotEmpty) DetailField(key: 'short_url', label: '短链', value: shortUrl.toString()),
        if (views != null) DetailField(key: 'views', label: '浏览量', value: views.toString()),
        if (fav != null) DetailField(key: 'favorites', label: '收藏量', value: fav.toString()),
        DetailField(key: 'resolution', label: '分辨率', value: resolution ?? '${w}x$h'),
        if (fileSize != null) DetailField(key: 'file_size', label: '大小', value: _humanSize(fileSize)),
        if ((fileType ?? '').isNotEmpty) DetailField(key: 'file_type', label: '格式', value: fileType!),
        if ((category ?? '').isNotEmpty) DetailField(key: 'category', label: '分类', value: _labelCategory(category)),
        if ((purity ?? '').isNotEmpty) DetailField(key: 'purity', label: '分级', value: _labelPurity(purity)),
        if ((sourceUrl?.toString() ?? '').isNotEmpty) DetailField(key: 'source', label: '来源', value: sourceUrl.toString()),
      ];

      return WallpaperDetailItem(
        sourceId: sourceId,
        id: (j['id'] as String?) ?? id,
        image: Uri.parse(path),
        width: w,
        height: h,
        author: (uploader?['username'] as String?),
        authorAvatar: Uri.tryParse((avatar?['200px'] as String?) ?? (avatar?['128px'] as String?) ?? ''),
        shortUrl: shortUrl,
        sourceUrl: sourceUrl,
        views: views,
        favorites: fav,
        resolution: resolution,
        ratio: ratio,
        fileSize: fileSize,
        fileType: fileType,
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