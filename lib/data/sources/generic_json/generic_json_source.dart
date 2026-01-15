import 'package:dio/dio.dart';

import '../../../domain/entities/dynamic_filter.dart';
import '../../../domain/entities/filter_spec.dart';
import '../../../domain/entities/option_item.dart';
import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/source_capabilities.dart';
import '../../../domain/entities/source_kind.dart';
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

  /// ✅ 允许 baseUrl 直接就是完整 endpoint（例如随机直链 API）
  final String baseUrl;
  final String searchPath; // 可空
  final String detailPath; // 可空
  final String? apiKey;

  /// ✅ settings 原样保留（mapping/capabilities/filters）
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

  // ----------------------------
  // kind：settings.kind 或 listKey=@direct 视为 random
  // ----------------------------
  @override
  SourceKind get kind {
    final k = (settings['kind'] ?? '').toString().trim().toLowerCase();
    if (k == 'random') return SourceKind.random;
    final listKey = (settings['listKey'] ?? '').toString().trim();
    if (listKey == '@direct') return SourceKind.random;
    return SourceKind.pagedSearch;
  }

  String _join(String base, String path) {
    final b = base.trim();
    final p = path.trim();
    if (p.isEmpty) return b;
    if (b.isEmpty) return p;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '$b$p';
    return '$b/$p';
  }

  Uri _safeUri(String s) => Uri.tryParse(s) ?? Uri.parse('about:blank');

  // ----------------------------
  // ✅ 从你给的自由 JSON（filters）生成 dynamicFilters
  // ----------------------------
  List<DynamicFilter> _dynamicFiltersFromLegacyFilters() {
    final raw = settings['filters'];
    if (raw is! List) return const [];
    final out = <DynamicFilter>[];

    for (final e in raw) {
      if (e is! Map) continue;
      final m = e.cast<String, dynamic>();

      final title = (m['title'] ?? '').toString().trim();
      final paramName = (m['paramName'] ?? '').toString().trim();
      final type = (m['type'] ?? '').toString().trim().toLowerCase();

      if (title.isEmpty || paramName.isEmpty) continue;
      if (type != 'radio') continue;

      final optsRaw = m['options'];
      if (optsRaw is! List) continue;

      final opts = <DynamicFilterOption>[];
      for (final o in optsRaw) {
        if (o is! Map) continue;
        final mm = o.cast<String, dynamic>();
        final label = (mm['label'] ?? '').toString().trim();
        final value = (mm['value'] ?? '').toString();
        if (label.isNotEmpty) {
          opts.add(DynamicFilterOption(label: label, value: value));
        }
      }
      if (opts.isEmpty) continue;

      out.add(
        DynamicFilter(
          title: title,
          paramName: paramName,
          type: DynamicFilterType.radio,
          options: opts,
        ),
      );
    }

    return out;
  }

  // ----------------------------
  // capabilities：优先 settings.capabilities，否则最小集 + legacy dynamicFilters
  // ----------------------------
  @override
  SourceCapabilities get capabilities {
    final caps = settings['capabilities'];
    if (caps is Map) {
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

      // dynamicFilters（可选）
      final dyn = <DynamicFilter>[];
      final dynRaw = m['dynamicFilters'];
      if (dynRaw is List) {
        for (final e in dynRaw) {
          if (e is! Map) continue;
          final mm = e.cast<String, dynamic>();
          final title = (mm['title'] ?? '').toString().trim();
          final paramName = (mm['paramName'] ?? '').toString().trim();
          final type = (mm['type'] ?? '').toString().trim().toLowerCase();

          if (title.isEmpty || paramName.isEmpty) continue;
          if (type != 'radio') continue;

          final optsRaw = mm['options'];
          if (optsRaw is! List) continue;

          final opts = <DynamicFilterOption>[];
          for (final o in optsRaw) {
            if (o is! Map) continue;
            final o2 = o.cast<String, dynamic>();
            final label = (o2['label'] ?? '').toString().trim();
            final value = (o2['value'] ?? '').toString();
            if (label.isNotEmpty) opts.add(DynamicFilterOption(label: label, value: value));
          }
          if (opts.isEmpty) continue;

          dyn.add(DynamicFilter(title: title, paramName: paramName, type: DynamicFilterType.radio, options: opts));
        }
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

        dynamicFilters: dyn,
      );
    }

    // 没给 capabilities：默认只支持关键词 + legacy filters（如果有）
    return SourceCapabilities(
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
      dynamicFilters: _dynamicFiltersFromLegacyFilters(),
    );
  }

  // ----------------------------
  // ✅ 参数构建：固定字段 + extras（最关键）
  // ----------------------------
  Map<String, dynamic> _buildParams(FilterSpec f, {int? page}) {
    final out = <String, dynamic>{};

    if (page != null) out['page'] = page;
    if (f.text.trim().isNotEmpty) out['q'] = f.text.trim();

    // ✅ 自定义参数（Luvbree 的 isNsfw / type / imageType 等）
    if (f.extras.isNotEmpty) {
      for (final e in f.extras.entries) {
        final k = e.key.trim();
        if (k.isEmpty) continue;
        out[k] = e.value;
      }
    }

    if (apiKey != null && apiKey!.isNotEmpty) {
      final apiKeyParam = (settings['apiKeyParam'] is String && (settings['apiKeyParam'] as String).trim().isNotEmpty)
          ? (settings['apiKeyParam'] as String).trim()
          : 'apikey';
      out[apiKeyParam] = apiKey;
    }

    return out;
  }

  // ----------------------------
  // ✅ 解码：支持三种返回
  // 1) listKey='@direct'：resp.data 直接就是图片直链（String）
  // 2) listKey 指向字段：root[listKey] 是 String 或 List
  // 3) 默认：root['data'] / root 本身
  // ----------------------------
  String? _extractDirectUrl(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      // 常见字段
      for (final k in ['url', 'image', 'path', 'src', 'data', 'link']) {
        final v = data[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return null;
  }

  @override
  Future<WallpaperItem?> random(FilterSpec filters) async {
    if (baseUrl.trim().isEmpty) return null;

    final url = _join(baseUrl, searchPath); // searchPath 可空
    try {
      final resp = await _http.dio.get(url, queryParameters: _buildParams(filters));
      if (resp.statusCode != 200) return null;

      final listKey = (settings['listKey'] ?? '').toString().trim();
      final root = resp.data;

      dynamic payload = root;
      if (listKey.isNotEmpty && listKey != '@direct' && root is Map && root.containsKey(listKey)) {
        payload = root[listKey];
      }

      if (listKey == '@direct') {
        final u = _extractDirectUrl(root) ?? _extractDirectUrl(payload);
        if (u == null) return null;
        return WallpaperItem(
          sourceId: sourceId,
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          preview: _safeUri(u),
          width: 0,
          height: 0,
          extra: (root is Map) ? root.cast<String, dynamic>() : const {},
        );
      }

      // payload 可能是 String / Map / List
      final direct = _extractDirectUrl(payload);
      if (direct != null) {
        return WallpaperItem(
          sourceId: sourceId,
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          preview: _safeUri(direct),
          width: 0,
          height: 0,
          extra: (payload is Map) ? payload.cast<String, dynamic>() : const {},
        );
      }

      // list
      if (payload is List) {
        for (final e in payload) {
          final u = _extractDirectUrl(e);
          if (u != null) {
            return WallpaperItem(
              sourceId: sourceId,
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              preview: _safeUri(u),
              width: 0,
              height: 0,
              extra: (e is Map) ? e.cast<String, dynamic>() : const {},
            );
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    // random 源不走分页搜索
    if (kind == SourceKind.random) return const [];

    if (baseUrl.trim().isEmpty) return const [];
    final url = _join(baseUrl, searchPath);

    try {
      final resp = await _http.dio.get(url, queryParameters: _buildParams(query.filters, page: query.page));
      if (resp.statusCode != 200) return const [];

      final root = resp.data;
      dynamic payload = root;

      // dataKey/listKey
      final dataKey = (settings['dataKey'] ?? settings['listKey'] ?? 'data').toString().trim();
      if (root is Map && root.containsKey(dataKey)) {
        payload = root[dataKey];
      }

      if (payload is! List) return const [];

      final items = <WallpaperItem>[];
      for (final e in payload) {
        final u = _extractDirectUrl(e);
        if (u == null) continue;
        items.add(
          WallpaperItem(
            sourceId: sourceId,
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            preview: _safeUri(u),
            width: 0,
            height: 0,
            extra: (e is Map) ? e.cast<String, dynamic>() : const {},
          ),
        );
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<WallpaperDetailItem?> detail(String id) async {
    // 对 generic/random：默认无详情（你要也能做，但先别强行）
    return null;
  }
}