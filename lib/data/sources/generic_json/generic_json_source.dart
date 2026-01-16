// lib/data/sources/generic_json/generic_json_source.dart
import 'package:dio/dio.dart';

import '../../../domain/entities/dynamic_filter.dart';
import '../../../domain/entities/filter_spec.dart';
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

  /// baseUrl 可以是 host，也可以是完整 endpoint
  final String baseUrl;

  /// 可选路径（用于 baseUrl=host 的情况）
  final String searchPath;
  final String detailPath;

  final String? apiKey;

  /// 原始 settings（filters / capabilities / mapping 等）
  final Map<String, dynamic> settings;

  GenericJsonSource({
    required this.sourceId,
    required HttpClient http,
    required this.baseUrl,
    this.searchPath = '',
    this.detailPath = '',
    required this.settings,
    this.apiKey,
  }) : _http = http;

  // =========================
  // Source kind
  // =========================
  @override
  SourceKind get kind {
    final k = (settings['kind'] ?? '').toString().trim().toLowerCase();
    if (k == 'random') return SourceKind.random;

    final listKey = (settings['listKey'] ?? '').toString().trim();
    if (listKey == '@direct') return SourceKind.random;

    return SourceKind.pagedSearch;
  }

  // =========================
  // Capabilities
  // 目前：最小集 + legacy filters -> dynamicFilters
  // =========================
  @override
  SourceCapabilities get capabilities {
    return SourceCapabilities(
      supportsText: true,
      dynamicFilters: _dynamicFiltersFromLegacyFilters(),
    );
  }

  List<DynamicFilter> _dynamicFiltersFromLegacyFilters() {
    final raw = settings['filters'];
    if (raw is! List) return const [];

    final out = <DynamicFilter>[];

    for (final e in raw) {
      if (e is! Map) continue;
      final m = e.cast<String, dynamic>();

      final title = (m['title'] ?? '').toString().trim();
      final param = (m['paramName'] ?? '').toString().trim();
      final type = (m['type'] ?? 'radio').toString().trim().toLowerCase();

      if (title.isEmpty || param.isEmpty) continue;
      if (type != 'radio') continue;

      final opts = <DynamicFilterOption>[];
      final rawOpts = m['options'];
      if (rawOpts is List) {
        for (final o in rawOpts) {
          if (o is! Map) continue;
          final mm = o.cast<String, dynamic>();
          final label = (mm['label'] ?? '').toString().trim();
          final value = (mm['value'] ?? '').toString();
          if (label.isNotEmpty) opts.add(DynamicFilterOption(label: label, value: value));
        }
      }

      if (opts.isEmpty) continue;

      out.add(
        DynamicFilter(
          title: title,
          paramName: param,
          type: DynamicFilterType.radio,
          options: opts,
        ),
      );
    }

    return out;
  }

  // =========================
  // URL join
  // =========================
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

  String? _extractUrl(dynamic x) {
    if (x is String) {
      final s = x.trim();
      return s.isEmpty ? null : s;
    }
    if (x is Map) {
      for (final k in const ['url', 'image', 'src', 'path', 'link', 'data']) {
        final v = x[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return null;
  }

  dynamic _pickPayload(dynamic root) {
    final listKey = (settings['listKey'] ?? '').toString().trim();
    if (listKey.isEmpty || listKey == '@direct') return root;

    if (root is Map && root.containsKey(listKey)) return root[listKey];
    return root;
  }

  // =========================
  // random
  // =========================
  @override
  Future<WallpaperItem?> random(FilterSpec filters) async {
    if (baseUrl.trim().isEmpty) return null;

    final url = _join(baseUrl, searchPath);
    try {
      final resp = await _http.dio.get(url, queryParameters: <String, dynamic>{
        ...filters.extras,
        if (filters.text.trim().isNotEmpty) 'q': filters.text.trim(),
        if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
      });

      if (resp.statusCode != 200) return null;

      final root = resp.data;
      final listKey = (settings['listKey'] ?? '').toString().trim();

      // 1) @direct：整个响应就当“直链/可提取直链”
      if (listKey == '@direct') {
        final u = _extractUrl(root) ?? _extractUrl(_pickPayload(root));
        if (u == null) return null;
        return _itemFromUrl(u, extra: (root is Map) ? root.cast<String, dynamic>() : const {});
      }

      // 2) payload 可以是 String / Map / List
      final payload = _pickPayload(root);
      final direct = _extractUrl(payload);
      if (direct != null) return _itemFromUrl(direct, extra: (payload is Map) ? payload.cast<String, dynamic>() : const {});

      if (payload is List) {
        for (final e in payload) {
          final u = _extractUrl(e);
          if (u != null) {
            return _itemFromUrl(u, extra: (e is Map) ? e.cast<String, dynamic>() : const {});
          }
        }
      }

      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================
  // search
  // =========================
  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    if (kind == SourceKind.random) return const [];
    if (baseUrl.trim().isEmpty) return const [];

    final url = _join(baseUrl, searchPath);
    try {
      final resp = await _http.dio.get(
        url,
        queryParameters: <String, dynamic>{
          'page': query.page,
          if (query.filters.text.trim().isNotEmpty) 'q': query.filters.text.trim(),
          ...query.filters.extras,
          if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
        },
      );

      if (resp.statusCode != 200) return const [];

      final root = resp.data;

      // dataKey/listKey: 默认 data
      final dataKey = (settings['dataKey'] ?? settings['listKey'] ?? 'data').toString().trim();
      dynamic payload = root;
      if (root is Map && root.containsKey(dataKey)) payload = root[dataKey];

      if (payload is! List) return const [];

      final out = <WallpaperItem>[];
      for (final e in payload) {
        final u = _extractUrl(e);
        if (u == null) continue;
        out.add(_itemFromUrl(u, extra: (e is Map) ? e.cast<String, dynamic>() : const {}));
      }
      return out;
    } on DioException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  // =========================
  // detail（通用源默认不支持）
  // =========================
  @override
  Future<WallpaperDetailItem?> detail(String id) async {
    return null;
  }

  // =========================
  // helpers
  // =========================
  WallpaperItem _itemFromUrl(String url, {Map<String, dynamic> extra = const {}}) {
    return WallpaperItem(
      sourceId: sourceId,
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      preview: _safeUri(url),
      width: 0,
      height: 0,
      extra: extra,
    );
  }
}