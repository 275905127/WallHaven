// lib/api/source_client.dart
import 'package:dio/dio.dart';
import '../models/wallpaper.dart';
import 'wallhaven_api.dart';

/// ✅ 统一接口：UI/业务层只认这个
abstract class WallpaperSourceClient {
  Future<List<Wallpaper>> search({
    int page,
    String sorting,
    String order,
    String? categories,
    String? purity,
    String? resolutions,
    String? ratios,
    String? query,
    String? atleast,
    String? colors,
    String? topRange,
  });

  Future<WallpaperDetail?> detail({required String id});
}

/// ✅ Wallhaven 插件实现：把 settings 映射成 WallhavenClient
class WallhavenSourceClient implements WallpaperSourceClient {
  final WallhavenClient _client;

  WallhavenSourceClient({
    Dio? dio,
    required String baseUrl,
    String? apiKey,
  }) : _client = WallhavenClient(
          dio: dio,
          baseUrl: baseUrl,
          apiKey: apiKey,
        );

  @override
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
  }) {
    return _client.search(
      page: page,
      sorting: sorting,
      order: order,
      categories: categories,
      purity: purity,
      resolutions: resolutions,
      ratios: ratios,
      query: query,
      atleast: atleast,
      colors: colors,
      topRange: topRange,
    );
  }

  @override
  Future<WallpaperDetail?> detail({required String id}) {
    return _client.detail(id: id);
  }
}