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
        dynamicFilters: dyn, // 确保这里返回 dynamicFilters
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
}
