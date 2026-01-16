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

  final String baseUrl;
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
    final k = (settings['kind'] ?? '').toString().toLowerCase();
    if (k == 'random') return SourceKind.random;
    if ((settings['listKey'] ?? '') == '@direct') return SourceKind.random;
    return SourceKind.pagedSearch;
  }

  // =========================
  // Capabilities
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

      final title = (m['title'] ?? '').toString();
      final param = (m['paramName'] ?? '').toString();
      if (title.isEmpty || param.isEmpty) continue;

      final opts = <DynamicFilterOption>[];
      final rawOpts = m['options'];
      if (rawOpts is List) {
        for (final o in rawOpts) {
          if (o is! Map) continue;
          final label = (o['label'] ?? '').toString();
          final value = (o['value'] ?? '').toString();
          if (label.isNotEmpty) {
            opts.add(DynamicFilterOption(label: label, value: value));
          }
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
  // random
  // =========================
  @override
  Future<WallpaperItem?> random(FilterSpec filters) async {
    if (baseUrl.isEmpty) return null;

    try {
      final resp = await _http.dio.get(baseUrl, queryParameters: filters.extras);
      if (resp.statusCode != 200) return null;

      final data = resp.data;
      if (data is String) {
        return _itemFromUrl(data);
      }
      if (data is Map) {
        final url = data['url'] ?? data['image'] ?? data['src'];
        if (url is String) return _itemFromUrl(url);
      }
    } catch (_) {}

    return null;
  }

  // =========================
  // search
  // =========================
  @override
  Future<List<WallpaperItem>> search(SearchQuery query) async {
    if (kind == SourceKind.random) return const [];
    if (baseUrl.isEmpty) return const [];

    try {
      final resp = await _http.dio.get(
        baseUrl,
        queryParameters: {
          ...query.filters.extras,
          'page': query.page,
        },
      );

      if (resp.statusCode != 200) return const [];

      final data = resp.data;
      if (data is! List) return const [];

      final out = <WallpaperItem>[];
      for (final e in data) {
        if (e is Map) {
          final url = e['url'] ?? e['image'] ?? e['src'];
          if (url is String) {
            out.add(_itemFromUrl(url));
          }
        }
      }
      return out;
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
  WallpaperItem _itemFromUrl(String url) {
    return WallpaperItem(
      sourceId: sourceId,
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      preview: Uri.parse(url),
      width: 0,
      height: 0,
      extra: const {},
    );
  }
}