// lib/sources/simple_json_source_plugin.dart
import 'package:dio/dio.dart';

import '../models/wallpaper.dart';
import 'source_plugin.dart';

/// =======================================
/// ✅ 第二图源：GenericJson（自定义 HTTP JSON）
/// =======================================
/// 目标：自由接入（不写死 Wallhaven）
///
/// 约定：
/// - 列表：GET {baseUrl}{searchPath}?page=1&...&apikey=xxx(可选)
///   返回：
///   1) { "data": [ { "id": "...", "thumb": "...", "url": "...", "width": 1920, "height": 1080 } ] }
///   或
///   2) [ { ... } ]  // 允许直接数组
///
/// - 详情：GET {baseUrl}{detailPath} 其中 {id} 替换
///   返回：
///   1) { "data": { ... } }
///   或
///   2) { ... }  // 允许直接对象
class SimpleJsonPlugin implements SourcePlugin {
  /// ✅ 必须和 SourceRegistry / ThemeStore 对齐
  static const String kId = 'generic';

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'Generic JSON';

  @override
  SourceConfig defaultConfig() {
    return const SourceConfig(
      id: 'default_generic',
      pluginId: kId,
      name: 'Generic JSON',
      settings: {
        'baseUrl': 'https://example.com/api',
        'searchPath': '/search',
        'detailPath': '/w/{id}',
        'apiKey': null,
      },
    );
  }

  @override
  Map<String, dynamic> sanitizeSettings(Map<String, dynamic> s) {
    final m = Map<String, dynamic>.from(s);

    String normBaseUrl(String? url) {
      var u = (url ?? '').trim();
      if (u.isEmpty) return u;
      if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
      while (u.endsWith('/')) u = u.substring(0, u.length - 1);
      return u;
    }

    String normPath(String? p, String fallback) {
      var v = (p ?? fallback).trim();
      if (v.isEmpty) v = fallback;
      if (!v.startsWith('/')) v = '/$v';
      return v;
    }

    String? normOpt(String? v) {
      final t = v?.trim();
      if (t == null || t.isEmpty) return null;
      return t;
    }

    m['baseUrl'] = normBaseUrl(m['baseUrl'] as String?);
    m['searchPath'] = normPath(m['searchPath'] as String?, '/search');
    m['detailPath'] = normPath(m['detailPath'] as String?, '/w/{id}');
    m['apiKey'] = normOpt(m['apiKey'] as String?);

    return m;
  }

  /// ✅ 修复点 1：签名必须和 SourcePlugin 完全一致（Dio? dio）
  @override
  WallpaperSourceClient createClient({
    required Map<String, dynamic> settings,
    Dio? dio,
  }) {
    final s = sanitizeSettings(settings);

    // ✅ 没注入就自己建一个，但这不是最佳实践（最好由上层注入共享 Dio）
    final clientDio = dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

    return _SimpleJsonClient(
      dio: clientDio,
      baseUrl: (s['baseUrl'] as String?) ?? '',
      searchPath: (s['searchPath'] as String?) ?? '/search',
      detailPath: (s['detailPath'] as String?) ?? '/w/{id}',
      apiKey: (s['apiKey'] as String?),
    );
  }
}

class _SimpleJsonClient implements WallpaperSourceClient {
  final Dio _dio;
  final String baseUrl;
  final String searchPath;
  final String detailPath;
  final String? apiKey;

  _SimpleJsonClient({
    required Dio dio,
    required this.baseUrl,
    required this.searchPath,
    required this.detailPath,
    required this.apiKey,
  }) : _dio = dio;

  String _join(String base, String path) {
    if (base.isEmpty) return path;
    if (path.isEmpty) return base;
    if (path.startsWith('/')) return '$base$path';
    return '$base/$path';
  }

  @override
  Future<List<Wallpaper>> search({
    required int page,
    required Map<String, dynamic> params,
I6866던
  }) async {
    if (baseUrl.isEmpty) return const [];

    try {
      final qp = <String, dynamic>{
        'page': page,
        ...params,
        if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
      };

      final resp = await _dio.get(
        _join(baseUrl, searchPath),
        queryParameters: qp,
      );

      if (resp.statusCode != 200) return const [];
      final data = resp.data;

      // ✅ 允许：{data:[...]}
      if (data is Map && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .whereType<Map>()
            .map((e) => _fromSimpleSearchJson(e.cast<String, dynamic>()))
            .toList();
      }

      // ✅ 允许：直接返回 [...]
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => _fromSimpleSearchJson(e.cast<String, dynamic>()))
            .toList();
      }

      return const [];
    } catch (e) {
      // ignore: avoid_print
      print('GenericJson search error: $e');
      return const [];
    }
  }

  @override
  Future<WallpaperDetail?> detail({required String id}) async {
    if (baseUrl.isEmpty) return null;

    try {
      final path = detailPath.replaceAll('{id}', id);
      final resp = await _dio.get(
        _join(baseUrl, path),
        queryParameters: {
          if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
        },
      );

      if (resp.statusCode != 200) return null;
      final data = resp.data;

      // ✅ 允许：{data:{...}}
      if (data is Map && data['data'] is Map) {
        final m = (data['data'] as Map).cast<String, dynamic>();
        return WallpaperDetail.fromDetailJson(m);
      }

      // ✅ 允许：直接返回 {...}
      if (data is Map) {
        final m = data.cast<String, dynamic>();
        return WallpaperDetail.fromDetailJson(m);
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('GenericJson detail error: $e');
      return null;
    }
  }

  /// ✅ 修复点 2：Wallpaper 构造函数 required: small + ratio
  Wallpaper _fromSimpleSearchJson(Map<String, dynamic> j) {
    final id = (j['id'] as String?) ?? '';
    final url = (j['url'] as String?) ?? (j['path'] as String?) ?? '';

    // thumb / small 多种字段兜底：thumb / preview / thumbs.small / thumbs.large
    final thumbsMap = (j['thumbs'] is Map) ? (j['thumbs'] as Map) : null;

    final thumb = (j['thumb'] as String?) ??
        (j['preview'] as String?) ??
        (thumbsMap?['large'] as String?) ??
        (thumbsMap?['small'] as String?) ??
        '';

    final small = (j['small'] as String?) ??
        (thumbsMap?['small'] as String?) ??
        (j['thumb_small'] as String?) ??
        thumb;

    final w = (j['width'] is int) ? j['width'] as int : int.tryParse('${j['width'] ?? ''}') ?? 0;
    final h = (j['height'] is int) ? j['height'] as int : int.tryParse('${j['height'] ?? ''}') ?? 0;

    // ratio：优先用接口给的，否则根据宽高算个可用值（避免 required 炸）
    final ratio = (j['ratio'] as String?)?.trim().isNotEmpty == true
        ? (j['ratio'] as String).trim()
        : ((w > 0 && h > 0) ? (w / h).toStringAsFixed(4) : '0');

    return Wallpaper(
      id: id,
      url: url,
      thumb: thumb,
      small: small,
      width: w,
      height: h,
      ratio: ratio,
    );
  }
}