import '../theme/theme_store.dart';
import 'http/http_client.dart';
import 'sources/generic_json/generic_json_source.dart';
import 'sources/wallhaven/wallhaven_source.dart';
import 'sources/wallpaper_source.dart';

class SourceFactory {
  final HttpClient http;

  SourceFactory({required this.http});

  WallpaperSource fromStore(ThemeStore store) {
    final cfg = store.currentSourceConfig;
    final pluginId = cfg.pluginId;
    final settings = store.currentSettings;

    if (pluginId == 'wallhaven') {
      // 你已有的：确保 baseUrl 从 settings 来
      final baseUrl = (settings['baseUrl'] as String?) ?? 'https://wallhaven.cc/api/v1';
      return WallhavenSource(
        sourceId: cfg.id,
        http: http,
        baseUrl: baseUrl,
        apiKey: (settings['apiKey'] as String?) ?? (settings['apikey'] as String?),
      );
    }

    if (pluginId == 'generic') {
      // ✅ 兼容你贴的自由 JSON：
      // { baseUrl: "https://.../api/image/random", listKey:"@direct", filters:[...] }
      final baseUrl = (settings['baseUrl'] as String?) ?? '';
      final searchPath = (settings['searchPath'] as String?) ?? ''; // 随机直链通常为空
      final detailPath = (settings['detailPath'] as String?) ?? '';
      final apiKey = (settings['apiKey'] as String?);

      return GenericJsonSource(
        sourceId: cfg.id,
        http: http,
        baseUrl: baseUrl,
        searchPath: searchPath,
        detailPath: detailPath,
        settings: settings,
        apiKey: apiKey,
      );
    }

    throw StateError('Unsupported pluginId: $pluginId');
  }
}