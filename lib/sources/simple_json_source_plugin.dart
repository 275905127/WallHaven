import 'package:dio/dio.dart';

import '../api/wallhaven_api.dart' show WallhavenClient; // 仅复用 normalize 逻辑？不需要的话删
import '../models/wallpaper.dart';
import 'source_plugin.dart';

/// =======================================
/// ✅ 第二图源：SimpleJson（自定义 HTTP JSON）
/// =======================================
/// 目标：给你一个“自由接入”的通用源，但不猜 header，不引入主题/UI
///
/// 约定接口：
/// - 搜索： GET {baseUrl}{searchPath}?page=1&...&apikey=xxx(可选)
///   返回： { "data": [ { "id": "...", "thumb": "...", "url": "...", "width": 1920, "height": 1080 } ] }
///
/// - 详情： GET {baseUrl}{detailPath} 其中 {id} 替换
///   返回： { "data": { ... WallpaperDetail 所需字段 ... } }
///
/// 说明：你如果是自建服务，就按这个 JSON 输出即可“一次接入，全站可用”。
class SimpleJsonPlugin implements SourcePlugin {
  static const String kId = 'simple_json';

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'SimpleJson';

  @override
  SourceConfig defaultConfig() {
    return const SourceConfig(
      id: 'default_simple_json',
      pluginId: kId,
      name: 'SimpleJson',
      settings: {
        'baseUrl': 'https://example.com/api', // 你自己改
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

  @override
  WallpaperSourceClient createClient({
    required Map<String, dynamic> settings,
    required Dio dio,
  }) {
    final s = sanitizeSettings(settings);
    return _SimpleJsonClient(
      dio: dio,
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

      if (data is Map && data['data'] is List) {
        final List list = data['data'] as List;
        return list
            .whereType<Map>()
            .map((e) => _fromSimpleSearchJson(e.cast<String, dynamic>()))
            .toList();
      }
      return const [];
    } catch (e) {
      // ignore: avoid_print
      print('SimpleJson search error: $e');
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

      if (data is Map && data['data'] is Map<String, dynamic>) {
        return WallpaperDetail.fromDetailJson(data['data'] as Map<String, dynamic>);
      }

      // 允许直接返回 detail 对象（不包 data）
      if (data is Map<String, dynamic>) {
        return WallpaperDetail.fromDetailJson(data);
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('SimpleJson detail error: $e');
      return null;
    }
  }

  /// 你现在 Wallpaper.fromSearchJson 是 Wallhaven 结构。
  /// SimpleJson 我给你一个“最小字段映射”，不够你就扩展。
  Wallpaper _fromSimpleSearchJson(Map<String, dynamic> j) {
    // 兼容字段名：thumb / thumbs->small / preview
    final thumb = (j['thumb'] as String?) ??
        (j['preview'] as String?) ??
        ((j['thumbs'] is Map) ? (j['thumbs']['small'] as String?) : null) ??
        '';

    final url = (j['url'] as String?) ?? '';
    final id = (j['id'] as String?) ?? '';

    final w = (j['width'] is int) ? j['width'] as int : int.tryParse('${j['width'] ?? ''}') ?? 1;
    final h = (j['height'] is int) ? j['height'] as int : int.tryParse('${j['height'] ?? ''}') ?? 1;

    return Wallpaper(
      id: id,
      url: url,
      thumb: thumb,
      width: w,
      height: h,
    );
  }
}