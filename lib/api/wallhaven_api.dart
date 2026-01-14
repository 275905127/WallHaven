import 'package:dio/dio.dart';
import '../models/wallpaper.dart';

class WallhavenApi {
  static final Dio _dio = Dio();

  /// 获取壁纸列表（支持完整筛选参数）
  static Future<List<Wallpaper>> getWallpapers({
    required String baseUrl,
    String? apiKey,
    int page = 1,

    // ===== 筛选参数（Wallhaven 官方）=====
    String sorting = 'toplist', // toplist / latest / random
    String order = 'desc', // desc / asc
    String? categories, // 111 / 100 / 010 / 001
    String? purity, // 100 / 110 / 111
    String? resolutions, // 1920x1080
    String? ratios, // 16x9
    String? query, // 关键词
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
          if (resolutions != null) 'resolutions': resolutions,
          if (ratios != null) 'ratios': ratios,
          if (query != null && query.isNotEmpty) 'q': query,
          if (apiKey != null && apiKey.isNotEmpty) 'apikey': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => Wallpaper.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Wallhaven API Error: $e");
      return [];
    }
  }
}