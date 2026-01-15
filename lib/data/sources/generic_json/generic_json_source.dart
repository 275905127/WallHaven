// lib/data/sources/generic_json/generic_json_source.dart
import 'package:dio/dio.dart';

import '../../../domain/entities/detail_field.dart';
import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/source_capabilities.dart';
import '../../../domain/entities/option_item.dart';
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

  final Map<String, dynamic> settings;

  GenericJsonSource({
    required this.sourceId,
    required HttpClient http,
    required this.baseUrl,
    required this.searchPath,
    required this.detailPath,
    required this.settings,
    this.apiKey,
  }) : _http = http;

  String _join(String base, String path) {
    if (base.isEmpty) return path;
    if (path.isEmpty) return base;
    if (path.startsWith('/')) return '$base$path';
    return '$base/$path';
  }

  // ----------------------------
  // capabilities
  // ----------------------------
  @override
  SourceCapabilities get capabilities => _capsFromSettings(settings);

  SourceCapabilities _capsFromSettings(Map<String, dynamic> s) {
    final caps = s['capabilities'];
    if (caps is! Map) {
      return const SourceCapabilities(
        supportsText: true,
        supportsSort: false,
        supportsOrder: false,
        supportsResolutions: false,
        supportsAtleast: false,
        supportsRatios: false,
        supportsColor: false,
        supportsRating: false,
        supportsCategories: false,
        supportsTimeRange: false,
      );
    }

    final m = caps.cast<String, dynamic>();

    bool b(String k, bool def) => (m[k] is bool) ? (m[k] as bool) : def;

    List<String> strList(String k) {
      final v = m[k];
      if (v is List) return v.map((e) => e?.toString() ?? '').where((e) => e.trim().isNotEmpty).toList();
      return const [];
    }

    List<OptionItem> optionList(String k) {
      final v = m[k];
      if (v is! List) return const [];
      final out = <OptionItem>[];
      for (final e in v) {
        if (e is Map) {
          final mm = e.cast<String, dynamic>();
          final id = (mm['id'] ?? '').toString().trim();
          final label = (mm['label'] ?? '').toString().trim();
          if (id.isNotEmpty && label.isNotEmpty) out.add(OptionItem(id: id, label: label));
        }
      }
      return out;
    }

    List<SortBy> sortList() {
      final raw = strList('sortByOptions');
      final out = <SortBy>[];
      for (final s in raw) {
        for (final e in SortBy.values) {
          if (e.name == s) out.add(e);
        }
      }
      return out;
    }

    List<RatingLevel> ratingList() {
      final raw = strList('ratingOptions');
      final out = <RatingLevel>[];
      for (final s in raw) {
        for (final e in RatingLevel.values) {
          if (e.name == s) out.add(e);
        }
      }
      return out;
    }

    return SourceCapabilities(
      supportsText: b('supportsText', true),

      supportsSort: b('supportsSort', false),
      sortByOptions: sortList(),

      supportsOrder: b('supportsOrder', false),

      supportsResolutions: b('supportsResolutions', false),
      resolutionOptions: strList('resolutionOptions'),

      supportsAtleast: b('supportsAtleast', false),
      atleastOptions: strList('atleastOptions'),

      supportsRatios: b('supportsRatios', false),
      ratioOptions: strList('ratioOptions'),

      supportsColor: b('supportsColor', false),
      colorOptions: strList('colorOptions'),

      supportsRating: b('supportsRating', false),
      ratingOptions: ratingList(),

      supportsCategories: b('supportsCategories', false),
      categoryOptions: optionList('categoryOptions'),

      supportsTimeRange: b('supportsTimeRange', false),
      timeRangeOptions: optionList('timeRangeOptions'),
    );
  }

  // ----------------------------
  // mapping
  // ----------------------------
  Map<String, dynamic> get _mapping {
    final mp = settings['mapping'];
    if (mp is Map) return mp.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  String _mapKey(String k, String fallback) {
    final v = _mapping[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return fallback;
  }

  String _dataKey() => _mapKey('dataKey', 'data');
  String _idKey() => _mapKey('id', 'id');
  String _previewKey() => _mapKey('preview', 'thumb');
  String _previewSmallKey() => _mapKey('previewSmall', 'small');
  String _originalKey() => _mapKey('original', 'url');
  String _widthKey() => _mapKey('width', 'width');
  String _heightKey() => _mapKey('height', 'height');

  dynamic _readPath(Map<String, dynamic> j, String path) {
    final p = path.trim();
    if (p.isEmpty) return null;
    if (!p.contains('.')) return j[p];

    dynamic cur = j;
    for (final part in p.split('.')) {
      if (cur is Map) cur = (cur as Map)[part];
      else return null;
    }
    return cur;
  }

  String _readString(Map<String, dynamic> j, String key, {String fallback = ''}) {
    final v = _readPath(j, key);
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  int _readInt(Map<String, dynamic> j, String key, {int fallback = 0}) {
    final v = _readPath(j, key);
    if (v is int) return v;
    final s = v?.toString().trim() ?? '';
    return int.tryParse(s) ?? fallback;
  }

  Uri _safeUri(String s) => Uri.tryParse(s) ?? Uri.parse('about:blank');

  // ----------------------------
  // FilterSpec -> queryParameters (通用输出)
  // ----------------------------
  Map<String, dynamic> _buildQueryParams(SearchQuery q) {
    final f = q.filters;

    final fk = settings['filterKeys'];
    final Map<String, dynamic> filterKeys = (fk is Map) ? fk.cast<String, dynamic>() : const {};

    String k(String name, String fallback) {
      final v = filterKeys[name];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return fallback;
    }

    final out = <String, dynamic>{
      k('page', 'page'): q.page,
    };

    if (f.text.trim().isNotEmpty) out[k('q', 'q')] = f.text.trim();

    final caps = capabilities;

    if (caps.supportsSort && f.sortBy != null) out[k('sortBy', 'sortBy')] = f.sortBy!.name;
    if (caps.supportsOrder && f.order != null) out[k('order', 'order')] = f.order!.name;
    if (caps.supportsResolutions && f.resolutions.isNotEmpty) {
      out[k('resolutions', 'resolutions')] = (f.resolutions.toList()..sort()).join(',');
    }
    if (caps.supportsAtleast && (f.atleast ?? '').trim().isNotEmpty) out[k('atleast', 'atleast')] = f.atleast!.trim();
    if (caps.supportsRatios && f.ratios.isNotEmpty) out[k('ratios', 'ratios')] = (f.ratios.toList()..sort()).join(',');
    if (caps.supportsColor && (f.color ?? '').trim().isNotEmpty) out[k('color', 'color')] = f.color!.trim().replaceAll('#', '');
    if (caps.supportsRating && f.rating.isNotEmpty) out[k('rating', 'rating')] = f.rating.map((e) => e.name).join(',');
    if (caps.supportsCategories && f.categories.isNotEmpty) out[k('categories', 'categories')] = (f.categories.toList()..sort()).join(',');
    if (caps.supportsTimeRange && (f.timeRange ?? '').trim().isNotEmpty) out[k('timeRange', 'timeRange')] = f.timeRange!.trim();

    if (apiKey != null && apiKey!.isNotEmpty) {
      final apiKeyParam = (settings['apiKeyParam'] is String && (settings['apiKeyParam'] as String).trim().isNotEmpty)
          ? (settings['apiKeyParam'] as String).trim()
          : 'apikey';
      out[apiKeyParam] = apiKey;
    }

    return out;
  }

  dynamic _unwrapRoot(dynamic root) {
    final key = _dataKey();
    if (root is Map && root[key] != null) return root[key];
    return root;
  }

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) return v.cast<String, dynamic>();
    return null;
  }

  // ----------------------------
  // Search
  // ----------------------------
  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    if (baseUrl.trim().isEmpty) return const [];

    try {
      final resp = await _http.dio.get(
        _join(baseUrl, searchPath),
        queryParameters: _buildQueryParams(query),
      );

      if (resp.statusCode != 200) return const [];

      final payload = _unwrapRoot(resp.data);
      final list = _asListOfMap(payload);

      final items = <WallpaperItem>[];
      for (final j in list) {
        final id = _readString(j, _idKey(), fallback: '');
        final preview = _readString(j, _previewKey(), fallback: '');
        final previewAlt = preview.isEmpty ? _readString(j, 'preview', fallback: '') : preview;
        final previewSmall = _readString(j, _previewSmallKey(), fallback: '');
        final original = _readString(j, _originalKey(), fallback: _readString(j, 'path', fallback: ''));

        final w = _readInt(j, _widthKey(), fallback: 0);
        final h = _readInt(j, _heightKey(), fallback: 0);

        final bestPreview = (previewAlt.isNotEmpty) ? previewAlt : (previewSmall.isNotEmpty ? previewSmall : original);
        if (id.trim().isEmpty || bestPreview.trim().isNotEmpty == false) continue;

        items.add(
          WallpaperItem(
            sourceId: sourceId,
            id: id,
            preview: _safeUri(bestPreview),
            previewSmall: previewSmall.isNotEmpty ? Uri.tryParse(previewSmall) : null,
            original: original.isNotEmpty ? Uri.tryParse(original) : null,
            width: w,
            height: h,
            extra: j,
          ),
        );
      }

      return items;
    } catch (_) {
      return const [];
    }
  }

  // ----------------------------
  // Detail
  // ----------------------------
  @override
  Future<WallpaperDetailItem?> detail(String id) async {
    if (baseUrl.trim().isEmpty) return null;

    try {
      final path = detailPath.replaceAll('{id}', id);

      final resp = await _http.dio.get(
        _join(baseUrl, path),
        queryParameters: <String, dynamic>{
          if (apiKey != null && apiKey!.isNotEmpty)
            ((settings['apiKeyParam'] is String && (settings['apiKeyParam'] as String).trim().isNotEmpty)
                ? (settings['apiKeyParam'] as String).trim()
                : 'apikey'): apiKey,
        },
      );

      if (resp.statusCode != 200) return null;

      final payload = _unwrapRoot(resp.data);
      final j = _asMap(payload);
      if (j == null) return null;

      final original = _readString(j, _originalKey(), fallback: _readString(j, 'path', fallback: ''));
      final preview = _readString(j, _previewKey(), fallback: _readString(j, 'thumb', fallback: ''));
      final imageUrl = original.isNotEmpty ? original : preview;
      if (imageUrl.isEmpty) return null;

      final w = _readInt(j, _widthKey(), fallback: 0);
      final h = _readInt(j, _heightKey(), fallback: 0);

      // tags/colors
      final tags = <String>[];
      final tagsRaw = j['tags'];
      if (tagsRaw is List) {
        for (final t in tagsRaw) {
          if (t is String && t.trim().isNotEmpty) tags.add(t.trim());
          if (t is Map) {
            final name = (t as Map).cast<String, dynamic>()['name'];
            if (name is String && name.trim().isNotEmpty) tags.add(name.trim());
          }
        }
      }

      final colors = <String>[];
      final colorsRaw = j['colors'];
      if (colorsRaw is List) {
        for (final c in colorsRaw) {
          final s = c?.toString().trim() ?? '';
          if (s.isNotEmpty) colors.add(s);
        }
      }

      final fields = <DetailField>[];

      void addField(String key, String label, dynamic value, {DetailFieldType? type}) {
        if (value == null) return;

        // type 明确指定：严格按 type
        if (type != null) {
          switch (type) {
            case DetailFieldType.text:
              final s = value.toString().trim();
              if (s.isEmpty) return;
              fields.add(DetailField.text(key: key, label: label, value: s));
              return;
            case DetailFieldType.url:
              final s = value.toString().trim();
              if (s.isEmpty) return;
              fields.add(DetailField.url(key: key, label: label, value: s));
              return;
            case DetailFieldType.number:
              if (value is num) {
                fields.add(DetailField.number(key: key, label: label, value: value));
                return;
              }
              final n = num.tryParse(value.toString().trim());
              if (n == null) return;
              fields.add(DetailField.number(key: key, label: label, value: n));
              return;
            case DetailFieldType.bytes:
              if (value is int) {
                fields.add(DetailField.bytes(key: key, label: label, value: value));
                return;
              }
              final n = int.tryParse(value.toString().trim());
              if (n == null) return;
              fields.add(DetailField.bytes(key: key, label: label, value: n));
              return;
          }
        }

        // 没指定 type：保守推断
        final s = value.toString().trim();
        if (s.isEmpty) return;

        final lowerKey = key.toLowerCase();
        final looksUrl = s.startsWith('http://') || s.startsWith('https://');
        if (looksUrl || lowerKey.contains('url') || lowerKey.contains('link')) {
          fields.add(DetailField.url(key: key, label: label, value: s));
          return;
        }

        final looksInt = int.tryParse(s) != null;
        if (looksInt && (lowerKey.contains('size') || lowerKey.contains('bytes'))) {
          fields.add(DetailField.bytes(key: key, label: label, value: int.parse(s)));
          return;
        }

        final looksNum = num.tryParse(s) != null;
        if (looksNum && (lowerKey.contains('count') || lowerKey.contains('views') || lowerKey.contains('fav'))) {
          fields.add(DetailField.number(key: key, label: label, value: num.parse(s)));
          return;
        }

        fields.add(DetailField.text(key: key, label: label, value: s));
      }

      // 一些通用字段（如果存在就展示）
      addField('author', '作者', j['author'] ?? j['uploader'] ?? j['username'], type: DetailFieldType.text);
      addField('short_url', '短链', j['short_url'] ?? j['shortUrl'], type: DetailFieldType.url);
      addField('views', '浏览量', j['views'], type: DetailFieldType.number);
      addField('favorites', '收藏量', j['favorites'], type: DetailFieldType.number);
      addField('resolution', '分辨率', j['resolution'] ?? (w > 0 && h > 0 ? '${w}x$h' : null), type: DetailFieldType.text);
      addField('file_type', '格式', j['file_type'] ?? j['fileType'], type: DetailFieldType.text);
      addField('file_size', '大小', j['file_size'] ?? j['fileSize'], type: DetailFieldType.bytes);
      addField('source', '来源', j['source'] ?? j['source_url'] ?? j['sourceUrl'], type: DetailFieldType.url);

      // ✅ 自定义额外字段：settings['detailFields'] = [{key,label,path,type}]
      final custom = settings['detailFields'];
      if (custom is List) {
        for (final e in custom) {
          if (e is! Map) continue;
          final mm = e.cast<String, dynamic>();

          final k = (mm['key'] ?? '').toString().trim();
          final label = (mm['label'] ?? '').toString().trim();
          final path2 = (mm['path'] ?? '').toString().trim();
          final typeRaw = (mm['type'] ?? '').toString().trim().toLowerCase();

          if (k.isEmpty || label.isEmpty || path2.isEmpty) continue;

          DetailFieldType? t;
          if (typeRaw == 'text') t = DetailFieldType.text;
          if (typeRaw == 'url') t = DetailFieldType.url;
          if (typeRaw == 'number') t = DetailFieldType.number;
          if (typeRaw == 'bytes') t = DetailFieldType.bytes;

          addField(k, label, _readPath(j, path2), type: t);
        }
      }

      return WallpaperDetailItem(
        sourceId: sourceId,
        id: _readString(j, _idKey(), fallback: id),
        image: _safeUri(imageUrl),
        width: w,
        height: h,
        shortUrl: Uri.tryParse((j['short_url'] ?? j['shortUrl'] ?? '').toString()),
        sourceUrl: Uri.tryParse((j['source'] ?? j['source_url'] ?? j['sourceUrl'] ?? '').toString()),
        author: (j['author'] ?? j['uploader'] ?? j['username'])?.toString(),
        authorAvatar: Uri.tryParse((j['authorAvatar'] ?? j['avatar'] ?? '').toString()),
        views: (j['views'] is int) ? j['views'] as int : int.tryParse('${j['views'] ?? ''}'),
        favorites: (j['favorites'] is int) ? j['favorites'] as int : int.tryParse('${j['favorites'] ?? ''}'),
        resolution: j['resolution']?.toString(),
        ratio: j['ratio']?.toString(),
        fileSize: (j['file_size'] is int) ? j['file_size'] as int : int.tryParse('${j['file_size'] ?? ''}'),
        fileType: (j['file_type'] ?? j['fileType'])?.toString(),
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