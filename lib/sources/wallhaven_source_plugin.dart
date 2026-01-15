import 'package:dio/dio.dart';
import '../models/wallpaper.dart';
import 'source_plugin.dart';

class WallhavenSourcePlugin implements SourcePlugin {
  static const String kId = 'wallhaven';
  static const String kDefaultBaseUrl = 'https://wallhaven.cc/api/v1';

  final Dio _dio = Dio();

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'Wallhaven';

  @override
  Map<String, dynamic> defaultSettings() => const {
        'baseUrl': kDefaultBaseUrl,
        'apiKey': null,
        'username': null,
      };

  String _baseUrl(Map<String, dynamic> s) {
    final u = s['baseUrl'];
    if (u is String && u.trim().isNotEmpty) return u.trim();
    return kDefaultBaseUrl;
  }

  String? _apiKey(Map<String, dynamic> s) {
    final k = s['apiKey'];
    if (k is String && k.trim().isNotEmpty) return k.trim();
    return null;
  }

  @override
  Future<SourceSearchResult> search({
    required Map<String, dynamic> settings,
    required int page,
    required Map<String, dynamic> filters,
  }) async {
    final baseUrl = _baseUrl(settings);
    final apiKey = _apiKey(settings);

    try {
      final response = await _dio.get(
        '$baseUrl/search',
        queryParameters: {
          'page': page,
          'sorting': (filters['sorting'] ?? 'toplist'),
          'order': (filters['order'] ?? 'desc'),
          if (filters['categories'] != null) 'categories': filters['categories'],
          if (filters['purity'] != null) 'purity': filters['purity'],
          if ((filters['resolutions'] ?? '').toString().isNotEmpty) 'resolutions': filters['resolutions'],
          if ((filters['ratios'] ?? '').toString().isNotEmpty) 'ratios': filters['ratios'],
          if ((filters['atleast'] ?? '').toString().isNotEmpty) 'atleast': filters['atleast'],
          if ((filters['colors'] ?? '').toString().isNotEmpty) 'colors': filters['colors'],
          if ((filters['topRange'] ?? '').toString().isNotEmpty) 'topRange': filters['topRange'],
          if ((filters['q'] ?? '').toString().isNotEmpty) 'q': filters['q'],
          if (apiKey != null) 'apikey': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List data = (response.data['data'] as List?) ?? const [];
        final items = data.map((e) => Wallpaper.fromSearchJson((e as Map).cast<String, dynamic>())).toList();
        return SourceSearchResult(items: items);
      }
      return const SourceSearchResult(items: []);
    } catch (_) {
      return const SourceSearchResult(items: []);
    }
  }

  @override
  Future<WallpaperDetail?> detail({
    required Map<String, dynamic> settings,
    required String id,
  }) async {
    final baseUrl = _baseUrl(settings);
    final apiKey = _apiKey(settings);

    try {
      final response = await _dio.get(
        '$baseUrl/w/$id',
        queryParameters: {if (apiKey != null) 'apikey': apiKey},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return WallpaperDetail.fromDetailJson(data);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
