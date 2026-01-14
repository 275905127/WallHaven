import 'package:dio/dio.dart';
import '../models/wallpaper.dart';

class WallhavenApi {
  static final Dio _dio = Dio();

  // 获取壁纸列表
  static Future<List<Wallpaper>> getWallpapers({
    required String baseUrl, // 从 ThemeStore 传入当前源地址
    String? apiKey,          // 从 ThemeStore 传入 API Key
    int page = 1,
  }) async {
    try {
      // 这里的 /search 是 Wallhaven 的标准搜索接口
      // 如果你是自定义图源，确保你的 API 兼容这个路径，或者在这里做适配
      final response = await _dio.get(
        '$baseUrl/search',
        queryParameters: {
          'page': page,
          'sorting': 'toplist', // 默认按榜单排序
          if (apiKey != null && apiKey.isNotEmpty) 'apikey': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => Wallpaper.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("API Error: $e");
      return [];
    }
  }
}
