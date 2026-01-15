import 'package:dio/dio.dart';
import '../models/wallpaper.dart';

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

  Future<List<Wallpaper>> search({
    int page = 1,
    String sorting = 'toplist',
    String order = 'desc',
    String? categories,
    String? purity,
    String? resolutions,
    String? ratios,
    String? query,
    String? atleast,
    String? colors,
    String? topRange,
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