// lib/api/wallhaven_api.dart
// ⚠️ 警示：此文件字段/参数必须以 Wallhaven 官方 API 为准，禁止私自改名/删参导致筛选失效。
// ⚠️ 警示：任何颜色/主题相关逻辑不要写进 API 层；这里只做网络与数据映射。

import 'package:dio/dio.dart';
import '../models/wallpaper.dart';

/// ================================
/// ✅ Wallhaven 插件客户端（新入口）
/// ================================
/// - 不依赖 ThemeStore / UI
/// - 可注入 Dio（后续可统一拦截器/日志/代理/超时）
/// - baseUrl/apiKey 可由插件配置提供
class WallhavenClient {
  static const String kDefaultBaseUrl = 'https://wallhaven.cc/api/v1';

  final Dio _dio;
  final String baseUrl;
  final String? apiKey;

  WallhavenClient({
    Dio? dio,
    String? baseUrl,
    this.apiKey,
  })  : _dio = dio ?? Dio(),
        baseUrl = _normalizeBaseUrl(baseUrl ?? kDefaultBaseUrl);

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// 获取壁纸列表（/search）
  Future<List<Wallpaper>> search({
    int page = 1,

    // ===== 搜索参数（按 Wallhaven /search）=====
    String sorting = 'toplist', // date_added / relevance / random / views / favorites / toplist
    String order = 'desc', // desc / asc
    String? categories, // 111 / 100 / 010 / 001
    String? purity, // 100 / 110 / 111
    String? resolutions, // 1920x1080
    String? ratios, // 16x9
    String? query, // q
    String? atleast, // 1920x1080
    String? colors, // e.g. "660000"
    String? topRange, // 1d / 3d / 1w / 1M / 3M / 6M / 1y
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/search',
        queryParameters: {
          'page': page,
          'sorting': sorting,
          'order': order,
          if (categories != null) 'categories': categories,
          if (purity != null) 'purity': purity,
          if (resolutions != null && resolutions.isNotEmpty) 'resolutions': resolutions,
          if (ratios != null && ratios.isNotEmpty) 'ratios': ratios,
          if (atleast != null && atleast.isNotEmpty) 'atleast': atleast,
          if (colors != null && colors.isNotEmpty) 'colors': colors,
          if (topRange != null && topRange.isNotEmpty) 'topRange': topRange,
          if (query != null && query.isNotEmpty) 'q': query,
          if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List data = (response.data['data'] as List?) ?? const [];
        return data
            .whereType<Map>()
            .map((e) => Wallpaper.fromSearchJson(e.cast<String, dynamic>()))
            .toList();
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print("Wallhaven API Error (search): $e");
      return [];
    }
  }

  /// 获取单张壁纸详情（/w/{id}）
  Future<WallpaperDetail?> detail({required String id}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/w/$id',
        queryParameters: {
          if (apiKey != null && apiKey!.isNotEmpty) 'apikey': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return WallpaperDetail.fromDetailJson(data);
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Wallhaven API Error (detail): $e");
      return null;
    }
  }
}
